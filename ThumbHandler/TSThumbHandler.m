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

#import "TSGroupContainerHelper.h"

#import <MagicalRecord/MagicalRecord.h>

/// Default JPEG quality for saved thumb images.
static const CGFloat TSThumbDefaultQuality = 0.74;

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
- (void) initCoreData;
- (void) initThumbQueue;

- (BOOL) hasThumbForImage:(TSThumbImageProxy *) image atUrl:(NSURL **) outUrl;

- (NSURL *) generateThumbnailForImage:(TSThumbImageProxy *) image withError:(NSError **) outErr;
- (BOOL) writeImage:(NSImage *) image toDiskAtUrl:(NSURL *) url withError:(NSError **) outErr;

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
 */
- (instancetype) initWithRemote:(id<TSThumbHandlerDelegate>) remote {
	if(self = [super init]) {
		// store reference to remote
		self.remote = remote;
		
		// perform various initializations
		[self initDiskCache];
		[self initCoreData];
		[self initThumbQueue];
	}
	
	return self;
}

/**
 * Sets up the on-disk cache.
 */
- (void) initDiskCache {
	NSError *err = nil;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// create directory, if needed
	[fm createDirectoryAtURL:self.thumbCacheUrl withIntermediateDirectories:YES
				  attributes:nil error:&err];
	
	if(err != nil) {
		DDLogError(@"Couldn't create thumb cache directory: %@", err);
	}
}

/**
 * Initializes the CoreData store.
 */
- (void) initCoreData {
	// get url for store
	NSURL *storeUrl = self.thumbCacheUrl;
	storeUrl = [storeUrl URLByAppendingPathComponent:@"ThumbCache.sqlite"
										 isDirectory:NO];
	
	// create the store
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreAtURL:storeUrl];
	});
	
	// create a context
	self.thumbMoc = [NSManagedObjectContext MR_context];
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
	
	// set up an operation to check for a thumbnail, and create one if needed
	op = [NSBlockOperation blockOperationWithBlock:^{
		BOOL hasThumb = NO;
		NSURL *url = nil;
		NSError *err = nil;
		
		// check whther a thumbnail exists
		hasThumb = [self hasThumbForImage:image atUrl:&url];
		if(hasThumb == YES) {
			// if so, run the completion callback
			[self.remote thumbnailGeneratedForIdentifier:completionIdentifier
												   atUrl:url];
			return;
		}
		
		// generate thumbnail
		url = [self generateThumbnailForImage:image withError:&err];
		
		if(url) {
			// thumbnail generated successfully
			[self.remote thumbnailGeneratedForIdentifier:completionIdentifier
												   atUrl:url];
		} else {
			// an error occurred
			[self.remote thumbnailFailedForIdentifier:completionIdentifier
											withError:err];
		}
	}];
	
	// set its quality of service to user initiated, if urgent
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
	
	// try to find a matching thumbnail
	pred = [NSPredicate predicateWithFormat:@"imageUuid = %@", image.uuid];
	thumb = [TSThumbnail MR_findFirstWithPredicate:pred
										 inContext:self.thumbMoc];
	
	if(thumb != nil) {
		if(outUrl != nil) {
			*outUrl = [thumb.thumbUrl copy];
			return YES;
		}
	}
	
	// a thumbnail must be created.
	return NO;
}

/**
 * Generates a thumbnail for the given image. If an error occurs, an `NSError`
 * object will be referenced by the pointer passed in as outErr, and nil is
 * returned. Otherwise, an URL to the given thumbnail is returned.
 */
- (NSURL *) generateThumbnailForImage:(TSThumbImageProxy *) image withError:(NSError **) outErr {
	BOOL written = NO;
	
	// TODO: actually create thumbnail
	NSURL *testUrl = [[NSBundle mainBundle] URLForResource:@"UnknownImage"
											 withExtension:@"png"];
	NSImage *thumbnailImg = [[NSImage alloc] initWithContentsOfURL:testUrl];
	
	// ensure thumbnail was successfully created
	if(thumbnailImg == nil) {
		return nil;
	}
	
	// get a directory and url for the image, then write it to disk
	NSString *dir = [TSThumbnail generateRandomDirectory];
	NSURL *url = [TSThumbnail urlForImageInDirectory:dir
									   andUuidString:image.uuid];
	
	written = [self writeImage:thumbnailImg toDiskAtUrl:url withError:outErr];

	if(written == NO) {
		return nil;
	}
	
	// create a thumbnail entry
	[MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *ctx) {
		TSThumbnail *thumb = [TSThumbnail MR_createEntityInContext:ctx];
		
		// populate its values
		thumb.dateAdded = thumb.dateLastAccessed = [NSDate new];
		
		thumb.directory = dir;
		thumb.imageUuid = image.uuid;
	}];
	
	// the image was saved and written, so return the url
	return url;
}

/**
 * Writes the given NSImage to disk as a JPEG.
 *
 * @return YES if the file was successfully written, NO otherwise.
 */
- (BOOL) writeImage:(NSImage *) image toDiskAtUrl:(NSURL *) url withError:(NSError **) outErr {
	__block NSBitmapImageRep *bitmapRep = nil;
	
	// find the bitmap image representation
	[image.representations enumerateObjectsUsingBlock:^(NSImageRep *rep, NSUInteger idx, BOOL *stop) {
		// is this one a bitmap rep?
		if([rep isKindOfClass:[NSBitmapImageRep class]]) {
			bitmapRep = (NSBitmapImageRep *) rep;
			
			*stop = YES;
		}
	}];
	
	// ensure there's a bitmap rep
	if(bitmapRep == nil) {
		DDLogError(@"Couldn't get bitmap rep for image: %@", image);
		return NO;
	}
	
	// try to get a JPEG representation
	NSData *jpegData = nil;
	NSDictionary *properties = nil;
	
	properties = @{
		// use default compression factor
		NSImageCompressionFactor: @(TSThumbDefaultQuality),
		// fallback background colour is black
		NSImageFallbackBackgroundColor: [NSColor blackColor]
	};
	
	jpegData = [bitmapRep representationUsingType:NSJPEG2000FileType
									   properties:properties];
	
	if(jpegData == nil) {
		DDLogError(@"Couldn't get jpeg data for image %@", image);
		return NO;
	}
	
	// write the JPEG data out to disk
	return [jpegData writeToURL:url options:NSDataWritingAtomic error:outErr];
}

#pragma mark Convenience Properties
/**
 * Returns the url of the thumbnail cache.
 */
- (NSURL *) thumbCacheUrl {	
	// query system for url
	NSURL *cachesUrl = [TSGroupContainerHelper sharedInstance].caches;
	cachesUrl = [cachesUrl URLByAppendingPathComponent:@"TSThumbCache" isDirectory:YES];
	
	return cachesUrl;
}

@end
