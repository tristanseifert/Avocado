//
//  TSThumbCache.m
//  Avocado
//
//  Created by Tristan Seifert on 20160501.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <math.h>

#import "TSThumbCache.h"

#import "TSThumbHandlerProtocol.h"
#import "TSHumanModels.h"

#import "TSThumbImageProxy+AvocadoApp.h"

#import "TSJPEG2000Parser.h"
#import "NSImage+TSCachedDecoding.h"

/**
 * Enables logging of lots of information regarding the smart image cache (when
 * it's resized, bag values, etc) is logged.
 */
#define	LOG_CACHE_DEBUG		0
/**
 * Enables logging of some thumbnail sizing calculations.
 */
#define	LOG_THUMB_SIZING	0
/**
 * Enables logging of thumbnail generation errors.
 */
#define	LOG_THUMB_ERRORS	1

/// Maximum number of thumbnail URLs to cache at a time
static const NSUInteger TSURLCacheMaxEntries = 250;

/**
 * Maximum number of images to store in the cache at scale level zero. Smaller
 * scale levels will cause this value to be multiplied by 1.74^(scaleLevel).
 */
static const NSUInteger TSImageCacheMaxImagesAtFullSize = 50;
/// Number of images that must be requested with a given scale before the cache is evicted
static const NSUInteger TSImageCacheImageThreshold = 8;
/// The lowest resolution scale value. By default, this is [0, 3] due to how the images are encoded.
static const NSUInteger TSImageCacheMaxScale = 3;



@interface TSThumbCacheCallbackWrapper : NSObject

/// Callback block to invoke
@property (nonatomic) TSThumbCacheCallback callbackBlock;
/// User data, if any
@property (nonatomic) void *userData;
/// Scale factor to use for the JPEG2000 data, based off the maximum thumbnail size.
@property (nonatomic) NSUInteger scaleFactor;

@end

@implementation TSThumbCacheCallbackWrapper
@end



/// Singleton thumb cache instance; created on first invocation of sharedInstance
static TSThumbCache *sharedInstance = nil;

@interface TSThumbCache ()

/// XPC connection to the thumb service
@property (nonatomic) NSXPCConnection *xpcConnection;

/// Temporary in-memory cache; maps an image UUID to its thumbnail URL
@property (nonatomic) NSCache *imageURLCache;

/*
 * The way the image cache works is kind of interesting. All images inside it
 * were loaded from a JPEG2000 image, using a specific 'scale' value; the larger
 * the scale value, the lower resolution the thumbnail is.
 *
 * 1. If an image request with that scale value comes through, the image is
 * simply retrieved from the cache.
 * 2. If an image request with a different scale value comes through, the
 * appropriate value in the `imageCacheRequestedSizes` value is set, adding to
 * that entry, if needed. If the reqeusted scale is higher than what the cache's
 * is, an image is returned anyways.
 *
 * Once any one value in `imageCacheRequestedSizes` has passed a threshold, the
 * cache is evicted, and its current scale becomes that value.
 */
/// Maps an image's UUID (plus scale value) to a cached image value.
@property (nonatomic) NSCache *imageCache;
/// Scale value for this cache
@property (atomic) NSInteger imageCacheScale;
/// Bag containing NSNumber objects for each requested size.
@property (atomic) CFMutableBagRef imageCacheRequestedSizes;

- (NSImage *) getCachedThumbForImageUuid:(NSString *) uuid andScale:(NSUInteger) scale;
- (void) storeThumbnail:(NSImage *) image withScale:(NSUInteger) scale forImageUuid:(NSString *) uuid;

/// Maps a temporary invocation identifier to a callback
@property (nonatomic) NSMutableDictionary <NSString *, NSMutableArray<TSThumbCacheCallbackWrapper *> *> *callbackMap;
/// Maps a temporary invocation identifier to an image uuid
@property (nonatomic) NSMutableDictionary <NSString *, NSString *> *imageUuidMap;
/// Queue used to synchronize access to callbackMap
@property (nonatomic, retain) dispatch_queue_t callbackAccessQueue;

/// Operation queue for loading images from disk.
@property (nonatomic) NSOperationQueue *imageLoadingQueue;

@end

@implementation TSThumbCache

/**
 * Returns the shared instance, creating it if needed.
 */
+ (instancetype) sharedInstance {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [TSThumbCache new];
	});
	
	return sharedInstance;
}

/**
 * Initializes the cache.
 */
- (instancetype) init {
	if(self = [super init]) {
		// Allocate some in-memory collections
		self.callbackMap = [NSMutableDictionary new];
		self.imageUuidMap = [NSMutableDictionary new];
		
		
		// Set up the image URL cache
		self.imageURLCache = [NSCache new];
		self.imageURLCache.evictsObjectsWithDiscardedContent = YES;
		self.imageURLCache.countLimit = TSURLCacheMaxEntries;
		
		// Set up the image cache
		self.imageCache = [NSCache new];
		self.imageCache.evictsObjectsWithDiscardedContent = YES;
		self.imageCache.countLimit = TSImageCacheMaxImagesAtFullSize;
		
		self.imageCacheScale = 0; // default scale value
		self.imageCacheRequestedSizes = CFBagCreateMutable(kCFAllocatorDefault, 0, &kCFTypeBagCallBacks);
		
		
		// Create a queue to synchronize access to the callback map
		self.callbackAccessQueue = dispatch_queue_create("me.tseifert.Avocado.TSThumbCache", DISPATCH_QUEUE_CONCURRENT);
		
		// Allocate an operation queue for loading images
		self.imageLoadingQueue = [NSOperationQueue new];
		
		self.imageLoadingQueue.qualityOfService = NSQualityOfServiceUserInitiated;
		self.imageLoadingQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
		
		// Allocate the XPC handle; it will be connected on the first invocation
		NSXPCInterface *intf;
		
		self.xpcConnection = [[NSXPCConnection alloc] initWithServiceName:@"me.tseifert.avocado.ThumbHandler"];
		
		intf = [NSXPCInterface interfaceWithProtocol:@protocol(TSThumbHandlerProtocol)];
		self.xpcConnection.remoteObjectInterface = intf;
		intf = [NSXPCInterface interfaceWithProtocol:@protocol(TSThumbHandlerDelegate)];
		self.xpcConnection.exportedInterface = intf;
		self.xpcConnection.exportedObject = self;
		
		// Set up some error handlers
		self.xpcConnection.interruptionHandler = ^{
			DDLogWarn(@"XPC connection to thumb handler invalidated");
		};
		
		// Allow the connection to be used
		[self.xpcConnection resume];
	}
	
	return self;
}

/**
 * Clean up some data when deallocating.
 */
- (void) dealloc {
	// invalidate XPC connection
	[self.xpcConnection invalidate];
}

/**
 * Runs a thumb request for the given image, using the specified size. If the
 * image is cached already, the callback is run immediately and no further
 * action is performed. It is assumed that the default priority is used.
 */
- (void) getThumbForImage:(TSLibraryImage *) inImage withSize:(NSSize) size andCallback:(TSThumbCacheCallback) callback withUserData:(void *) userData {
	[self getThumbForImage:inImage withSize:size andCallback:callback
			  withUserData:userData andPriority:kTSThumbHandlerDefault];
}

/**
 * Creates a thumbnail for the given size, at the specified size. If the image
 * has already been generated, and is in the cache, the callback is executed
 * immediately and the method returns.
 *
 * Otherwise, if the thumbnail is not in the cache, a request is made to the
 * XPC service to generate the thumbnail, and some information is stored so that
 * the callbacks can be executed when the image is produced.
 *
 * If this call is made multiple times, for the same image, before the XPC
 * service returns data, the callback is added to the existing request.
 *
 * @param inImage Input image, for which to generate the thumbnail
 * @param size Requested size; there is no guarantee that the image will be this
 * size; it is simply used as a hint in processing the image.
 * @param callback Callback to execute when the image is complete.
 * @param userData Pointer to arbitrary data passed to the callback.
 * @param priority Relative priority of the thumbnail request.
 */
- (void) getThumbForImage:(TSLibraryImage *) inImage withSize:(NSSize) size andCallback:(TSThumbCacheCallback) callback withUserData:(void *) userData andPriority:(TSThumbHandlerUrgency) priority {
	__block NSString *inImageUuid = nil;
	__block NSSize imageSize;
	
	// Get some information from the input image
	[inImage.managedObjectContext performBlockAndWait:^{
		inImageUuid = inImage.uuid;
		imageSize = inImage.rotatedImageSize;
	}];
	
	// Figure out the JPEG2000 scale factor to use in this image.
	BOOL horizontalLongEdge = (imageSize.width > imageSize.height);
	CGFloat maxDimension = horizontalLongEdge ? size.width : size.height;
	
	CGFloat desiredFactor = log2(TSThumbMaxSize / maxDimension);
	NSUInteger scaleFactor = MAX(MIN(round(desiredFactor), TSImageCacheMaxScale), 0);
	
#if LOG_THUMB_SIZING
	DDLogVerbose(@"Scale factor for size %@: %zi (max dimension = %f; factor = %f)", NSStringFromSize(size), scaleFactor, maxDimension, desiredFactor);
#endif
	
	// Check if a suitable image exists in the cache.
	NSImage *cachedImage = [self getCachedThumbForImageUuid:inImageUuid
												   andScale:scaleFactor];
	
	if(cachedImage) {
		// Run the callback right away and return, since a suitable image exists.
		callback(cachedImage, userData);
		
		return;
	}
	
	
	// Check whether there is an outstanding request for this image already
	__block BOOL addedToExistingRequest = NO;
	
	dispatch_sync(self.callbackAccessQueue, ^{
		NSArray *keys = [self.imageUuidMap allKeysForObject:inImageUuid];
		
		// Use the first key: there should only be one
		if(keys.count != 0) {
			addedToExistingRequest = YES;
			
			// If the request already exists, just add the callback
			if(callback != nil) {
				dispatch_barrier_async(self.callbackAccessQueue, ^{
					TSThumbCacheCallbackWrapper *wrapper = [TSThumbCacheCallbackWrapper new];
					wrapper.userData = userData;
					wrapper.callbackBlock = [callback copy];
					wrapper.scaleFactor = scaleFactor;
					
					[self.callbackMap[keys.firstObject] addObject:wrapper];
				});
			}
		}
	});
	
	if(addedToExistingRequest) {
		return;
	}
	
	
	// Otherwise, insert the callback into the callback map and queue an XPC request
	NSString *identifier = [NSUUID new].UUIDString;
	
	dispatch_barrier_async(self.callbackAccessQueue, ^{
		if(callback) {
			TSThumbCacheCallbackWrapper *wrapper = [TSThumbCacheCallbackWrapper new];
			wrapper.userData = userData;
			wrapper.callbackBlock = [callback copy];
			wrapper.scaleFactor = scaleFactor;
			self.callbackMap[identifier] = [NSMutableArray arrayWithObject:wrapper];
		} else {
			self.callbackMap[identifier] = [NSMutableArray new];
		}
		
		self.imageUuidMap[identifier] = inImageUuid;
	});
	
	// Request the XPC thumb generation
	TSThumbImageProxy *proxy = [TSThumbImageProxy proxyForImage:inImage];
	[self.xpcConnection.remoteObjectProxy fetchThumbForImage:proxy
												withPriority:priority
											   andIdentifier:identifier];
}


/**
 * Pre-fills the cache by requesting that the XPC service generates a thumb for
 * a newly created image. This runs at the lowest priority possible.
 */
- (void) warmCacheWithThumbForImage:(TSLibraryImage *) inImage {
	[self getThumbForImage:inImage withSize:NSZeroSize
			   andCallback:nil withUserData:nil
			   andPriority:kTSThumbHandlerBackground];
}

#pragma mark XPC Service Callbacks
/**
 * When the thumbnail generation completes successfully for an image previously
 * requested, this callback is executed.
 *
 * @param identifier Value passed to fetchThumbForImage:isUrgent:withIdentifier:
 * @param url Url of the thumbnail image.
 */
- (void) thumbnailGeneratedForIdentifier:(NSString *) identifier atUrl:(NSURL *) url {
	__block NSString *imageUuid = nil;
	__block NSArray<TSThumbCacheCallbackWrapper *> *callbacks;
	
	// Get the uuid of the image, and the callbacks
	dispatch_sync(self.callbackAccessQueue, ^{
		callbacks = self.callbackMap[identifier];
		imageUuid = self.imageUuidMap[identifier];
	});
	
	// Save the URL in the cache
	[self.imageURLCache setObject:url forKey:imageUuid];
	
	// Check that there's callbacks to run
	if(callbacks.count > 0) {
		// Run on a background queue, so the image loading won't hang the UI thread
		[self.imageLoadingQueue addOperationWithBlock:^{
			// Execute callbacks
			[callbacks enumerateObjectsUsingBlock:^(TSThumbCacheCallbackWrapper *wrapper, NSUInteger idx, BOOL *stop) {
				// Decode the image at the requested scale factor, then run the callback
				NSImage *img = [TSJPEG2000Parser jpeg2kFromUrl:url
											  withQualityLayer:wrapper.scaleFactor];
				
				wrapper.callbackBlock(img, wrapper.userData);
				
				// Store it in the cache
				[self storeThumbnail:img withScale:wrapper.scaleFactor
						forImageUuid:imageUuid];
			}];
			
			// Remove the state objects
			dispatch_barrier_async(self.callbackAccessQueue, ^{
				[self.callbackMap removeObjectForKey:identifier];
				[self.imageUuidMap removeObjectForKey:identifier];
			});
		}];
	} else {
		// Remove the state objects
		dispatch_barrier_async(self.callbackAccessQueue, ^{
			[self.callbackMap removeObjectForKey:identifier];
			[self.imageUuidMap removeObjectForKey:identifier];
		});
	}
}

/**
 * If an unexpected error occurs during thumbnail processing (i.e. the file is
 * unreadable, or the raw image does not contain a valid thumbnail) this method
 * is called. If an error is available, it is passed in as well.
 *
 * @param identifier Value passed to fetchThumbForImage:isUrgent:withIdentifier:
 * @param error An `NSError` object describing the error, if applicable.
 */
- (void) thumbnailFailedForIdentifier:(NSString *) identifier withError:(NSError *) error {
	// Get the image completion callblacks
	__block NSArray<TSThumbCacheCallbackWrapper *> *callbacks;

	dispatch_sync(self.callbackAccessQueue, ^{
		callbacks = self.callbackMap[identifier];
	});
	
	// Check that there's callbacks to run
	if(callbacks.count > 0) {
		// Load a default 'error' image
		NSImage *img = [NSImage imageNamed:NSImageNameCaution];
		
		// Execute callbacks
		[callbacks enumerateObjectsUsingBlock:^(TSThumbCacheCallbackWrapper *wrapper, NSUInteger idx, BOOL *stop) {
			wrapper.callbackBlock(img, wrapper.userData);
		}];
	}
	
#if LOG_THUMB_ERRORS
	DDLogError(@"Error getting thumbnail for %@: %@", identifier, error);
#endif
	
	// Remove state for this image
	dispatch_barrier_async(self.callbackAccessQueue, ^{
		[self.callbackMap removeObjectForKey:identifier];
		[self.imageUuidMap removeObjectForKey:identifier];
	});
}

#pragma mark Image Cache Handling
/**
 * Checks whether the cache contains a thumbnail for the given image's UUID at
 * the specified scale level.
 *
 * If a suitable image is found, it will be returned. Nil is returned otherwise.
 */
- (NSImage *) getCachedThumbForImageUuid:(NSString *) uuid andScale:(NSUInteger) scale {
	// Is the scale for the image different?
	if(scale != self.imageCacheScale) {
		// If so, insert it into the bag of scales
		CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, kCFNumberNSIntegerType, &scale);
		CFBagAddValue(self.imageCacheRequestedSizes, number);
		
		// Did this bring the count past the threshold?
		NSUInteger count = CFBagGetCountOfValue(self.imageCacheRequestedSizes, number);
	
		if(count > TSImageCacheImageThreshold) {
			// If so, clear the cache, and set this as the new scale
			self.imageCacheScale = scale;
			[self.imageCache removeAllObjects];
			
			// Also update the cache's maximum count
			CGFloat multiply = pow(1.74f, (CGFloat) self.imageCacheScale);
			CGFloat newCacheValue = (TSImageCacheMaxImagesAtFullSize * multiply);
			
			self.imageCache.countLimit = (NSUInteger) newCacheValue;
			
#if LOG_CACHE_DEBUG
			// Print debug info
			NSMutableString *str = [NSMutableString new];
			
			for(NSInteger i = 0; i <= TSImageCacheMaxScale; i++) {
				CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, kCFNumberNSIntegerType, &i);
				NSUInteger count = CFBagGetCountOfValue(self.imageCacheRequestedSizes, number);
				
				NSString *subStr = [NSString stringWithFormat:@"Scale %02zi: %zi\n", i, count];
				[str appendString:subStr];
			}
			
			DDLogVerbose(@"TSThumbCache changing to scale factor %zi (count = %zi), statistics:\n%@", scale, self.imageCache.countLimit, str);
#endif
			
			// Empty the bag (reset cache state)
			CFBagRemoveAllValues(self.imageCacheRequestedSizes);
			
			// Since the cache was emptied, do not use it.
			return nil;
		}
		
		// If the requested scale is smaller than the image scale, no suitable image is in the cache.
		if(scale < self.imageCacheScale) {
			return nil;
		}
	}
	
	// The scale is the same (or smaller than) what's in the cache; return an object, if it exists.
	return [self.imageCache objectForKey:uuid];
}

/**
 * Stores an image of the given scale factor in the cache. If the cache is for
 * images of a different scale, nothing happens.
 *
 * @note This does _not_ add the scale factor to the scale factor bag. This is
 * done when the presence of an image in the cache is checked. While that
 * approach may result in over-counting (multiple requests for the same image
 * will trigger the cache reading multiple times, whereas the cache set method
 * is only executed once) that is desireable, as it provides are more accurate
 * view of how the cache is used.
 */
- (void) storeThumbnail:(NSImage *) image withScale:(NSUInteger) scale forImageUuid:(NSString *) uuid {
	// Is the image's scale factor the same as that of the cache?
	if(scale == self.imageCacheScale) {
		// If so, stick it in the cache.
		[self.imageCache setObject:image forKey:uuid];
	}
	
	// Otherwise, ignore the request.
}

@end
