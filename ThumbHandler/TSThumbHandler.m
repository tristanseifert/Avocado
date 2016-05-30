//
//  TSThumbHandler.m
//  ThumbHandler
//
//  Created by Tristan Seifert on 20160528.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSThumbHandler.h"
#import "TSThumbImageProxy.h"
#import "TSThumbCacheHumanModels.h"
#import "TSRawThumbExtractor.h"
#import "TSGroupContainerHelper.h"

#import <ImageIO/ImageIO.h>

/**
 * Set this define to 1 to prevent thumbnail data from being saved to the
 * CoreData store. This is useful for debugging.
 */
#define	DO_NOT_SAVE_THUMBS	0

/// KVO context value for the operations count
static void *TSKVOOpCountCtx = &TSKVOOpCountCtx;

/// Default JPEG quality for saved thumb images.
static const CGFloat TSThumbDefaultQuality = 0.64;
/// Maximum size of a thumbnail, on the long edge
static const CGFloat TSThumbMaxSize = 1024.f;

@interface TSThumbHandler ()

/// URL to the thumbnail cache directory
@property (readonly, getter=thumbCacheUrl) NSURL *thumbCacheUrl;
/// Thumb generation queue
@property (nonatomic) NSOperationQueue *thumbQueue;
/// Secret managed object context
@property (nonatomic) NSManagedObjectContext *thumbMoc;

/// Remote object to receive callbacks
@property (nonatomic, strong) id<TSThumbHandlerDelegate> remote;

- (void) initDiskCache;
- (void) initCoreDataWithParent:(NSManagedObjectContext *) parent;
- (void) initThumbQueue;

- (BOOL) hasThumbForImage:(TSThumbImageProxy *) image atUrl:(NSURL **) outUrl;

- (NSURL *) generateThumbnailForImage:(TSThumbImageProxy *) image withError:(NSError **) outErr;
- (BOOL) writeImage:(CGImageRef) image toDiskAtUrl:(NSURL *) url withError:(NSError **) outErr;

- (CGImageRef) createBitmapThumbnailForImage:(TSThumbImageProxy *) image withError:(NSError **) outErr;

@end

@implementation TSThumbHandler

#pragma mark Initialization
/**
 * Sets up a few things upon initialization; namely, the CoreData store in which
 * all the thumbnail metadata is stored, as well as the thumbnail generation
 * queue and the on-disk cache structure.
 *
 * @param remote Object exported by the remote end of the XPC connectionl; this
 * object receives all notifications about completed thumb operations.
 * @param parentCtx Parent managed object context, associated with a persistent
 * store on disk.
 */
- (instancetype) initWithRemote:(id<TSThumbHandlerDelegate>) remote andContext:(NSManagedObjectContext *) parentCtx {
	if(self = [super init]) {
		// Store reference to remote
		self.remote = remote;
		
		// Perform various initializations
		[self initDiskCache];
		[self initCoreDataWithParent:parentCtx];
		[self initThumbQueue];
	}
	
	return self;
}

/**
 * Cleans up a few things upon deallocation.
 */
- (void) dealloc {
	@try {
		[self.thumbQueue removeObserver:self forKeyPath:@"operationCount"];
	} @catch (__unused NSException *exception) { /* lol fuck KVO */ }
}

/**
 * Sets up the on-disk cache.
 */
- (void) initDiskCache {
	NSError *err = nil;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// Create directory, if needed
	[fm createDirectoryAtURL:self.thumbCacheUrl withIntermediateDirectories:YES
				  attributes:nil error:&err];
	
	if(err != nil) {
		DDLogError(@"Couldn't create thumb cache directory: %@", err);
	}
}

/**
 * Initializes the CoreData store.
 */
- (void) initCoreDataWithParent:(NSManagedObjectContext *) parent {
	// Create a MOC with the specified parent
	self.thumbMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	[self.thumbMoc setParentContext:parent];
	
	self.thumbMoc.name = [NSString stringWithFormat:@"TSThumbHandlerMoc %p", self];
}

/**
 * Allocates an operation queue on which thumbnail generation requests will be
 * executed.
 */
- (void) initThumbQueue {
	self.thumbQueue = [NSOperationQueue new];
	
	self.thumbQueue.name = [NSString stringWithFormat:@"TSThumbHandlerQueue %p", self];
	self.thumbQueue.qualityOfService = NSQualityOfServiceBackground;
	self.thumbQueue.maxConcurrentOperationCount = 2;
	
	// Add observer for operation count
	[self.thumbQueue addObserver:self forKeyPath:@"operationCount"
						 options:0 context:TSKVOOpCountCtx];
}

#pragma mark KVO
/**
 * Handles KVO changes. When the operation queue's current operation count has
 * reached zero (i.e. it is idle, and there are no more thumbnails to be
 * generated,) the managed object context will be saved.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	if(context == TSKVOOpCountCtx) {
		// Save the MOC, if operation count is zero
		if(self.thumbQueue.operationCount == 0) {
			NSError *err = nil;
			
			if([self.thumbMoc save:&err] == NO) {
				DDLogError(@"Couldn't save thumbnails: %@", err);
				return;
			}
			
			// Save the parent context (saves context to disk)
			NSManagedObjectContext *parent = self.thumbMoc.parentContext;
			
			if([parent save:&err] == NO) {
				DDLogError(@"Couldn't save parent context: %@", err);
				return;
			}
		}
	} else {
		// Invoke super
		[super observeValueForKeyPath:keyPath ofObject:object change:change
							  context:context];
	}
}

#pragma mark Thumb Creation
/**
 * Requests that a thumbnail is generated for the given image. If the thumbnail
 * does not exist, it will be created and stored on-disk. Otherwise, the path
 * to the image is fetched from the database and returned.
 *
 * @param image An image object, containing some pertinent information about it.
 * @param urgent If this parameter is set, it indicates that the user is most
 * likely waiting on the thumbnail (i.e. some list was scrolled, and thumbnails
 * need to be shown) and it should be given a higher priority.
 * @param completionIdentifier Passed as an argument to the delegate when the
 * thumbnail has been generated.
 */
- (void) fetchThumbForImage:(TSThumbImageProxy *) image isUrgent:(BOOL) urgent
			 withIdentifier:(NSString *) completionIdentifier {
	NSBlockOperation *op;
	
	// Set up an operation to check for a thumbnail, and create one if needed
	op = [NSBlockOperation blockOperationWithBlock:^{
		BOOL hasThumb = NO;
		NSURL *url = nil;
		NSError *err = nil;
		
		// Check whther a thumbnail exists
		hasThumb = [self hasThumbForImage:image atUrl:&url];
		if(hasThumb == YES) {
			// If so, run the completion callback
			[self.remote thumbnailGeneratedForIdentifier:completionIdentifier
												   atUrl:url];
			return;
		}
		
		// Generate thumbnail
		url = [self generateThumbnailForImage:image withError:&err];
		
		if(url) {
			// Thumbnail generated successfully
			[self.remote thumbnailGeneratedForIdentifier:completionIdentifier
												   atUrl:url];
		} else {
			// An error occurred
			[self.remote thumbnailFailedForIdentifier:completionIdentifier
											withError:err];
		}
	}];
	
	// Set its quality of service to user initiated, if urgent
	if(urgent) {
		op.qualityOfService = NSQualityOfServiceUserInitiated;
	}
	
	[self.thumbQueue addOperation:op];
}

/**
 * Checks whether a thumbnail exists for the given image. If so, the output
 * url parameter is populated with the url to the thumb, if non-nil.
 */
- (BOOL) hasThumbForImage:(TSThumbImageProxy *) image atUrl:(NSURL **) outUrl {
	TSThumbnail *thumb = nil;
	NSPredicate *pred = nil;
	
	// Try to find a matching thumbnail
	pred = [NSPredicate predicateWithFormat:@"imageUuid = %@", image.uuid];
	
	NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Thumbnail"];
	req.predicate = pred;
	req.fetchLimit = 1;
	
	__block NSArray *results = nil;
	
	[self.thumbMoc performBlockAndWait:^{
		NSError *err = nil;
		
		// Execute fetch request on the context's queue
		results = [self.thumbMoc executeFetchRequest:req error:&err];
		
		// Check for errors during fetch
		if(results == nil || err != nil) {
			DDLogError(@"Couldn't run fetch request (%@): %@", pred, err);
		}
	}];
	
	// Thumbnail must be created, if count is zero (i.e. no matching thumb)
	if(results == nil || results.count == 0) {
		return NO;
	} else {
		// A thumbnail was found; update its last accessed date
		thumb = results.firstObject;
		
		thumb.dateLastAccessed = [NSDate new];
		
		// Output the URL of the thumbnail image
		if(outUrl != nil) {
			*outUrl = [thumb.thumbUrl copy];
		}
		
		// It is possible outUrl was ignored, so return YES here
		return YES;
	}
}

/**
 * Generates a thumbnail for the given image. If an error occurs, an `NSError`
 * object will be referenced by the pointer passed in as outErr, and nil is
 * returned. Otherwise, an URL to the given thumbnail is returned.
 */
- (NSURL *) generateThumbnailForImage:(TSThumbImageProxy *) image withError:(NSError **) outErr {
	BOOL written = NO;
	CGImageRef thumbnailImg = nil;
	
	// Create thumbnail, depending on if the image is a raw file or not
	if(image.isRaw == NO) {
		thumbnailImg = [self createBitmapThumbnailForImage:image
												 withError:outErr];
	} else {
		TSRawThumbExtractor *extract = nil;
		
		// Create the thumbnail extractor and
		extract = [[TSRawThumbExtractor alloc] initWithRawFile:image.originalUrl];
		thumbnailImg = [extract extractThumbWithSize:TSThumbMaxSize];
	}
	
	// Ensure thumbnail was successfully created before continuing on
	if(thumbnailImg == nil) {
		return nil;
	}
	
	// Get a directory and url for the image, then write it to disk
	NSString *dir = [TSThumbnail generateRandomDirectory];
	NSURL *url = [TSThumbnail urlForImageInDirectory:dir
									   andUuidString:image.uuid];
	
	written = [self writeImage:thumbnailImg toDiskAtUrl:url withError:outErr];

	if(written == NO) {
		return nil;
	}
	
	// Create a thumbnail object in the CoreData store
#if DO_NOT_SAVE_THUMBS
	// Do nothing
#else
	[self.thumbMoc performBlock:^{
		TSThumbnail *thumb =  [NSEntityDescription insertNewObjectForEntityForName:@"Thumbnail" inManagedObjectContext:self.thumbMoc];
		
		thumb.dateAdded = thumb.dateLastAccessed = [NSDate new];
		
		thumb.directory = dir;
		thumb.imageUuid = image.uuid;
	}];
#endif
	
	// Clean up
	CGImageRelease(thumbnailImg);
	
	// The image was saved and written, so return the url
	return url;
}

/**
 * Writes the given NSImage to disk as a JPEG.
 *
 * @return YES if the file was successfully written, NO otherwise.
 */
- (BOOL) writeImage:(CGImageRef) image toDiskAtUrl:(NSURL *) url withError:(NSError **) outErr {
	CGImageDestinationRef destination = nil;
	
	// Set up some options for compression
	CFMutableDictionaryRef options = CFDictionaryCreateMutable(nil, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	CFNumberRef quality = (__bridge CFNumberRef) @(TSThumbDefaultQuality);
	CFDictionarySetValue(options, kCGImageDestinationLossyCompressionQuality, quality);
	
	// Create the image destination
	destination = CGImageDestinationCreateWithURL((__bridge CFURLRef) url, kUTTypeJPEG2000, 1, NULL);

	if(destination == nil) {
		DDLogError(@"CGImageDestinationCreateWithURL failed for url %@", url);
		return NO;
	}
	
	// Add the image and write it
	CGImageDestinationAddImage(destination, image, options);
	CGImageDestinationFinalize(destination);

	// Clean up
	CFRelease(destination);
	CFRelease(options);
	
	return YES;
}

#pragma mark Bitmap Image Thumb Creation
/**
 * Uses ImageIO to generate a thumbnail for the specified file.
 */
- (CGImageRef) createBitmapThumbnailForImage:(TSThumbImageProxy *) image withError:(NSError **) outErr {
	CGImageSourceRef source = NULL;
	CGImageRef thumb = NULL;
	
	// Create an image source
	source = CGImageSourceCreateWithURL((__bridge CFURLRef) image.originalUrl, nil);
	
	if(source == NULL) {
		DDLogError(@"Couldn't create image source for %@", image.originalUrl);
		return nil;
	}
	
	// Set up thumbnail options, then generate the thumb
	NSDictionary *thumbOptions = @{
		// Always create a new thumb
		(NSString *) kCGImageSourceCreateThumbnailFromImageAlways: @YES,
		// Transform (rotate/scale according to pixel ratio)
		(NSString *) kCGImageSourceCreateThumbnailWithTransform: @YES,
		// Maximum size
		(NSString *) kCGImageSourceThumbnailMaxPixelSize: @(TSThumbMaxSize)
	};
	
	thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, (CFDictionaryRef) thumbOptions);
	
	if(thumb == NULL) {
		DDLogError(@"Couldn't create thumb for %@, settings %@", image.originalUrl, thumbOptions);
		return nil;
	}
	
	// Done with thumb generation
	return thumb;
}

#pragma mark Convenience Properties
/**
 * Returns the url of the thumbnail cache.
 */
- (NSURL *) thumbCacheUrl {
	NSURL *cachesUrl = [TSGroupContainerHelper sharedInstance].caches;
	cachesUrl = [cachesUrl URLByAppendingPathComponent:@"TSThumbCache" isDirectory:YES];
	
	return cachesUrl;
}

@end
