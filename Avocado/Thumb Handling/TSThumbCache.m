//
//  TSThumbCache.m
//  Avocado
//
//  Created by Tristan Seifert on 20160501.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSThumbCache.h"

#import "TSThumbHandlerProtocol.h"
#import "TSHumanModels.h"
#import "TSThumbImageProxy+AvocadoApp.h"

static TSThumbCache *sharedInstance = nil;

@interface TSThumbCacheCallbackWrapper : NSObject

/// Callback block to invoke
@property (nonatomic) TSThumbCacheCallback callbackBlock;
/// User data, if any
@property (nonatomic) void *userData;

@end

@implementation TSThumbCacheCallbackWrapper

@end



@interface TSThumbCache ()

/// XPC connection to the thumb service
@property (nonatomic) NSXPCConnection *xpcConnection;
/// Temporary in-memory cache; maps an image UUID to an NSImage
@property (nonatomic) NSCache *imageCache;

/// Maps a temporary invocation identifier to a callback
@property (nonatomic) NSMutableDictionary <NSString *, NSMutableArray<TSThumbCacheCallbackWrapper *> *> *callbackMap;
/// Maps a temporary invocation identifier to an image uuid
@property (nonatomic) NSMutableDictionary <NSString *, NSString *> *imageUuidMap;
/// Queue used to synchronize access to callbackMap
@property (nonatomic, retain) dispatch_queue_t callbackAccessQueue;

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
		// Qllocate some in-memory collections
		self.callbackMap = [NSMutableDictionary new];
		self.imageUuidMap = [NSMutableDictionary new];
		
		self.imageCache = [NSCache new];
		
		// Create a queue to synchronize access to the callback map
		self.callbackAccessQueue = dispatch_queue_create("me.tseifert.Avocado.TSThumbCache", DISPATCH_QUEUE_CONCURRENT);
		
		
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
	
	// Get some information from the input image
	[inImage.managedObjectContext performBlockAndWait:^{
		inImageUuid = inImage.uuid;
	}];
	
	// Check if the image exists in the cache
	if([self.imageCache objectForKey:inImageUuid] != nil) {
		// If so, immediately return to the callback
		NSImage *image = (NSImage *) [self.imageCache objectForKey:inImageUuid];
		callback(image, userData);
		
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
	
	// Check that there's callbacks to run
	if(callbacks.count > 0) {
		// Read the image from the url and store in cache
		NSImage *img = [[NSImage alloc] initWithContentsOfURL:url];
		[self.imageCache setObject:img forKey:imageUuid];
		
		// Execute callbacks
		[callbacks enumerateObjectsUsingBlock:^(TSThumbCacheCallbackWrapper *wrapper, NSUInteger idx, BOOL *stop) {
			wrapper.callbackBlock(img, wrapper.userData);
		}];
	}
	
	// Remove the state
	dispatch_barrier_async(self.callbackAccessQueue, ^{
		[self.callbackMap removeObjectForKey:identifier];
		[self.imageUuidMap removeObjectForKey:identifier];
	});
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
	
//	DDLogError(@"Error getting thumbnail for %@: %@", identifier, error);
	
	// Remove state for this image
	dispatch_barrier_async(self.callbackAccessQueue, ^{
		[self.callbackMap removeObjectForKey:identifier];
		[self.imageUuidMap removeObjectForKey:identifier];
	});
}

@end
