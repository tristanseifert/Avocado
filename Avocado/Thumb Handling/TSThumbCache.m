//
//  TSThumbCache.m
//  Avocado
//
//  Created by Tristan Seifert on 20160501.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSThumbCache.h"

#import "TSHumanModels.h"
#import "TSRawImage.h"

#import <ImageIO/ImageIO.h>
#import <Cocoa/Cocoa.h>

static TSThumbCache *sharedInstance = nil;

@interface TSThumbCache ()

/// this queue gets thumb requests submitted on it
@property (nonatomic) NSOperationQueue *queue;
/// temporary in-memory cache
@property (nonatomic) NSCache *imageCache;

- (NSImage *) createThumb:(NSURL *) image forSize:(NSSize) size;
- (NSImage *) extractThumbFromFile:(NSURL *) url;

- (NSImage *) rotateImage:(NSImage *) image angle:(NSInteger) alpha;

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
		// set up queue (used for thumb requests)
		self.queue = [NSOperationQueue new];
		
		self.queue.qualityOfService = NSQualityOfServiceUtility;
		self.queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
		
		self.queue.name = @"TSThumbCache";
		
		// set up cache
		self.imageCache = [NSCache new];
	}
	
	return self;
}

/**
 * Runs a thumb request for the given image, using the specified size. If the
 * image is cached already, the callback is run immediately and no further
 * action is performed.
 *
 * @note There is absolutely no guarantee as to which thread the callback is
 * executed on.
 *
 * @note The callback may be called more than once, with a more fitting
 * thumbnail each time.
 */
- (void) getThumbForImage:(TSLibraryImage *) inImage withSize:(NSSize) size andCallback:(TSThumbCacheCallback) callback {
	NSBlockOperation *extractThumbOp, *createThumbOp;
	
	// get the string used as the key, and look up in the cache
	__block NSString *key = [NSString stringWithFormat:@"%@_%@", inImage.thumbUUID, NSStringFromSize(size)];
	
//	DDLogInfo(@"Creating thumb sized %@ for image (fault = %i, url = %@, uuid = %@, key = %@)", NSStringFromSize(size), image.isFault, image.fileUrl, image.thumbUUID, key);
	
	if([self.imageCache objectForKey:key] != nil) {
		callback([self.imageCache objectForKey:key]);
		return;
	}
	
	// get some info from the image (this way, we need not create a new queue)
	__block NSURL *inUrl = inImage.fileUrl;
	BOOL isRaw = (inImage.fileTypeValue == TSLibraryImageRaw);
	
	// for non-RAW images, use ImageIO
	if(isRaw == NO) {
		// extract a thumbnail from the file
		extractThumbOp = [NSBlockOperation blockOperationWithBlock:^{
			NSImage *extracted = [self extractThumbFromFile:inUrl];
			
			if(extracted) {
				callback(extracted);
			} else {
				DDLogWarn(@"Couldn't extract thumb from %@; deferring to thumb creation", inUrl);
			}
		}];
		
		// create an operation that will render a thumbnail
		createThumbOp = [NSBlockOperation blockOperationWithBlock:^{
			// make a thumbnail
			NSImage *thumb = [self createThumb:inUrl forSize:size];
			
			// store it and execute callback
			if(thumb) {
				[self.imageCache setObject:thumb forKey:key];

				callback(thumb);
			} else {
				DDLogError(@"Couldn't create thumbnail for %@; is it a valid image?", inUrl);
				
				callback([NSImage imageNamed:NSImageNameCaution]);
			}
		}];
		
		[createThumbOp addDependency:extractThumbOp];
		
		// queue these operations
		[self.queue addOperation:extractThumbOp];
		[self.queue addOperation:createThumbOp];
	} else {
		// otherwise, make use of LibRAW
		extractThumbOp = [NSBlockOperation blockOperationWithBlock:^{
			NSError *err = nil;
			
			// create a RAW parser
			TSRawImage *img = [[TSRawImage alloc] initWithContentsOfUrl:inUrl error:&err];
			
			if(err) {
				DDLogError(@"Couldn't create RAW handle for %@: %@", inUrl, err);
				callback([NSImage imageNamed:NSImageNameCaution]);
			} else {
				// extract the thumbnail, and apply rotation if needed
				NSImage *thumb = img.thumbnail;
				
				// if non-zero size, continue
				if(NSEqualSizes(thumb.size, NSZeroSize) == NO) {
					if(img.rotation != 0) {
						thumb = [self rotateImage:thumb angle:img.rotation];
					}
				
					// store the converted thumb and execute callback
					[self.imageCache setObject:thumb forKey:key];
					callback(thumb);
				} else {
					// otherwise, show a caution icon
					callback([NSImage imageNamed:NSImageNameCaution]);
					
					DDLogInfo(@"Got thumb with zero size for %@", inUrl);
				}
			}
		}];
		
		// queue operations
		[self.queue addOperation:extractThumbOp];
	}
}

#pragma mark Thumb Creation
/**
 * Creates a thumb, using ImageIO; this creates thumbnails very quickly, at
 * the expense of some quality.
 */
- (NSImage *) createThumb:(NSURL *) url forSize:(NSSize) size {
	CGImageSourceRef imageSource = NULL;
	CGImageRef thumb = NULL;
	
	// create an image source
	imageSource = CGImageSourceCreateWithURL((CFURLRef) url, NULL);
	
	if(imageSource == NULL) {
		DDLogError(@"Couldn't create image source for %@", url);
		return nil;
	}
	
	// set up thumbnail options, then generate the thumb
	NSDictionary *thumbOptions = @{
		// always create a new thumb
		(NSString *) kCGImageSourceCreateThumbnailFromImageAlways: @YES,
		// transform (rotate/scale according to pixel ratio)
		(NSString *) kCGImageSourceCreateThumbnailWithTransform: @YES,
		// take the longer value of the size
		(NSString *) kCGImageSourceThumbnailMaxPixelSize: @((size.width > size.height) ? size.width : size.height)
	};
	
	thumb = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef) thumbOptions);
	
	if(thumb == NULL) {
		DDLogError(@"Couldn't create thumb for %@, settings %@", url, thumbOptions);
		return nil;
	}
	
	// create an NSImage
	return [[NSImage alloc] initWithCGImage:thumb size:NSZeroSize];
}

/**
 * Extracts an embedded thumbnail from an image file.
 */
- (NSImage *) extractThumbFromFile:(NSURL *) url {
	CGImageRef        thumbImage = NULL;
	CGImageSourceRef  imgSource;
	CFDictionaryRef   thumbOpts = NULL;
	
	CFStringRef       myKeys[3];
	CFTypeRef         myValues[3];
 
	// Create an image source from NSData; no options.
	imgSource = CGImageSourceCreateWithURL((__bridge CFURLRef) url, NULL);
	
	// Make sure the image source exists before continuing.
	if (imgSource == NULL) {
		DDLogError(@"Could not create image source for %@", url);
		return nil;
	}
 
	// Set up the thumbnail options.
	myKeys[0] = kCGImageSourceCreateThumbnailWithTransform;
	myValues[0] = (CFTypeRef) kCFBooleanTrue;
	myKeys[1] = kCGImageSourceCreateThumbnailFromImageIfAbsent;
	myValues[1] = (CFTypeRef) kCFBooleanTrue;
	
	//	myKeys[2] = kCGImageSourceThumbnailMaxPixelSize;
	//	myValues[2] = (CFTypeRef) CFNumberCreate(NULL, kCFNumberIntType, &imageSize);
 
	thumbOpts = CFDictionaryCreate(NULL, (const void **) myKeys,
								   (const void **) myValues, 1,
								   &kCFTypeDictionaryKeyCallBacks,
								   & kCFTypeDictionaryValueCallBacks);
 
	// Create the thumbnail image using the specified options.
	thumbImage = CGImageSourceCreateThumbnailAtIndex(imgSource, 0, thumbOpts);
	
	// release options and image source
	CFRelease(thumbOpts);
	CFRelease(imgSource);
 
	// Make sure the thumbnail image exists before continuing.
	if(thumbImage == NULL){
		DDLogError(@"Could not create thumbnail image for %@", url);
		return nil;
	}
	
	// convert thumb image
	return [[NSImage alloc] initWithCGImage:thumbImage size:NSZeroSize];
}

#pragma mark Image Manipulation
/**
 * Rotates the given image.
 */
- (NSImage *) rotateImage:(NSImage *) image angle:(NSInteger) degrees {
	degrees = fmod(degrees, 360);
	
	// exit if there is no rotation to actually do
	if (0 == degrees) {
		return image;
	}
	
	// calculate size of the new image
	NSSize size = [image size];
	NSSize maxSize;
	if (90 == degrees || 270 == degrees || -90 == degrees || -270 == degrees) {
		maxSize = NSMakeSize(size.height, size.width);
	} else if (180. == degrees || -180. == degrees) {
		maxSize = size;
	}
	
	// set up the rotation transform
	NSAffineTransform *rot = [NSAffineTransform transform];
	[rot rotateByDegrees:-degrees];
	
	// centering transform
	NSAffineTransform *center = [NSAffineTransform transform];
	[center translateXBy:maxSize.width / 2 yBy:maxSize.height / 2];
	[rot appendTransform:center];
	
	// create the new image
	NSImage *newImage = [[NSImage alloc] initWithSize:maxSize];
	[newImage lockFocus];
	
	// do something with the transform pls
	[rot concat];
	
	// draw old image
	NSRect rect = NSMakeRect(0, 0, size.width, size.height);
	NSPoint corner = NSMakePoint(-size.width / 2, -size.height / 2);
	
	[image drawAtPoint:corner fromRect:rect
			 operation:NSCompositeCopy fraction:1.0];
	
	// done
	[newImage unlockFocus];
	return newImage;
}

@end
