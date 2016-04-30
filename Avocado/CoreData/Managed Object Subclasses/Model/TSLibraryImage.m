#import "TSLibraryImage.h"

#import "NSDate+AvocadoUtils.h"

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

/// context indicating that the date shot has changed
static void *TSLibraryImageDateShotKVOCtx = &TSLibraryImageDateShotKVOCtx;

@interface TSLibraryImage ()

// internal properties
@property (nonatomic) NSImage *thumbImageCache;

- (void) addKVO;

@end

@implementation TSLibraryImage
@dynamic metadata, fileUrl, fileTypeValue, dayShotValue;

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
	
	// remove KVO observers
	[self removeObserver:self forKeyPath:@"dateShots"];
	
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
		
	}
	
	// return the cache
	return self.thumbImageCache;
}

#pragma mark ImageKit Support
/**
 * Returns an unique id for ImageKit caching; in this case, the managed objec
 * id.
 */
- (NSString *) imageUID {
	return self.objectID.URIRepresentation.absoluteString;
}

/**
 * The image representation provided; for this class, this is an NSImage
 * created from thumbnail data if RAW, or a path if it's a non-RAW file.
 */
- (NSString *) imageRepresentationType {
	switch (self.fileTypeValue) {
		case TSLibraryImageRaw:
			return IKImageBrowserNSImageRepresentationType;
			
		case TSLibraryImageCompressed:
			return IKImageBrowserNSURLRepresentationType;
	}
}

/**
 * Actually returns the image representation to use in rendering the image.
 */
- (id) imageRepresentation {
	switch (self.fileTypeValue) {
		// for uncompressed (raw) images, get the thumbnail from memory
		case TSLibraryImageRaw:
			return self.thumbnail;
			
		// for compressed images, return the url of the file
		case TSLibraryImageCompressed:
			return return self.fileUrl;
	}
}

/**
 * Returns an image 'version,' which is used to indicate that the image view
 * must update this image.
 */
- (NSUInteger) imageVersion {
	return 1;
}

/**
 * Returns the caption. This is either the filename, if the caption is nil,
 * or the metadata caption field.
 */
- (NSString *) imageTitle {
	return self.fileUrl.lastPathComponent;
}

/**
 * Returns a subtitle: this can be the image's size, or some other piece of
 * metadata.
 */
- (NSString *) imageSubtitle {
	return @"9999 x 9999";
}

@end
