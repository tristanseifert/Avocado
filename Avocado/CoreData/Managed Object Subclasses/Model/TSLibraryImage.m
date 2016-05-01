#import "TSLibraryImage.h"
#import "TSRawImage.h"
#import "NSDate+AvocadoUtils.h"

#import <ImageIO/ImageIO.h>
#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

/// context indicating that the date shot has changed
static void *TSLibraryImageDateShotKVOCtx = &TSLibraryImageDateShotKVOCtx;

@interface TSLibraryImage ()

// internal properties
@property (nonatomic) NSImage *thumbImageCache;

- (void) addKVO;
- (void) extractThumbImageIO;

@end

@implementation TSLibraryImage
@dynamic metadata, fileUrl, fileTypeValue, dayShotValue;
@synthesize thumbImageCache;

#pragma mark Lifecycle
/**
 * Called when the object is first fetched from a managed object context.
 */
- (void) awakeFromFetch {
	[super awakeFromFetch];
	
	[self addKVO];
}

/**
 * Called when the object is first inserted into a managed object context.
 */
- (void) awakeFromInsert {
	[super awakeFromInsert];
	
	[self addKVO];
}

/**
 * Removes the KVO observers when the object turns into a fault.
 */
- (void) willTurnIntoFault {
	[super willTurnIntoFault];
	
	// remove KVO observers (fuck this shit)
	@try {
		[self removeObserver:self forKeyPath:@"dateShots"];
	} @catch (NSException __unused *exception) { }
	
	// clear thumb cache
	self.thumbImageCache = nil;
}

#pragma mark KVO
/**
 * Adds KVO observers.
 */
- (void) addKVO {
	[self addObserver:self forKeyPath:@"dateShot" options:0
			  context:TSLibraryImageDateShotKVOCtx];
}

/**
 * KVO handler
 */
- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	if(context == TSLibraryImageDateShotKVOCtx) {
		// set the "dayShot" to the date, sans time component
		self.dayShotValue = [self.dateShot timeIntervalSince1970WithoutTime];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Thumbnail
/**
 * Getter for the thumbnail property. Causes the thumbnail to be loaded from
 * disk if required.
 */
- (NSImage *) thumbnail {
	if(self.thumbImageCache == nil) {
		// is it a RAW image?
		if(self.fileTypeValue == TSLibraryImageRaw) {
			TSRawImage *raw = nil;
			NSError *err = nil;
			
			// load the image
			raw = [[TSRawImage alloc] initWithContentsOfUrl:self.fileUrl
													  error:&err];
			
			if(err) {
				DDLogError(@"Couldn't open %@: %@", self.fileUrl, err);
				self.thumbImageCache = [NSImage imageNamed:NSImageNameCaution];
				
				return self.thumbImageCache;
			}
			
			// extract thumbnail
			if(raw.thumbnail != nil) {
				self.thumbImageCache = raw.thumbnail;
			} else {
				DDLogError(@"No thumbnail in %@; do something useful here", self.fileUrl);
				self.thumbImageCache = [NSImage imageNamed:NSImageNameMultipleDocuments];
			}
		} else if(self.fileTypeValue == TSLibraryImageCompressed) {
			// use ImageIO
			[self extractThumbImageIO];
		}
	}
	
	// return the cache
	return self.thumbImageCache;
}

/**
 * Extracts any embedded thumbnails from the compressed image file, if they
 * exist; if not, ImageIO will create one in memory.
 */
- (void) extractThumbImageIO {
	CGImageRef        thumbImage = NULL;
	CGImageSourceRef  imgSource;
	CFDictionaryRef   thumbOpts = NULL;
	
	CFStringRef       myKeys[3];
	CFTypeRef         myValues[3];
	
	CFNumberRef       thumbnailSize;
 
	// Create an image source from NSData; no options.
	imgSource = CGImageSourceCreateWithURL((__bridge CFURLRef) self.fileUrl, NULL);
	
	// Make sure the image source exists before continuing.
	if (imgSource == NULL){
		DDLogError(@"Could not create image source for %@", self.fileUrl);
		return;
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
//	CFRelease(thumbnailSize);
	CFRelease(thumbOpts);
	CFRelease(imgSource);
 
	// Make sure the thumbnail image exists before continuing.
	if(thumbImage == NULL){
		DDLogError(@"Could not create thumbnail image for %@", self.fileUrl);
		return;
	}
	
	// convert thumb image
	self.thumbImageCache = [[NSImage alloc] initWithCGImage:thumbImage size:NSZeroSize];
}

@end
