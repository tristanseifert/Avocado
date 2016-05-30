#import "TSThumbnail.h"
#import "TSGroupContainerHelper.h"

#import <Security/Security.h>

@interface TSThumbnail ()

// Private interface goes here.

@end

@implementation TSThumbnail

/**
 * Gets the url to the thumbnail image.
 */
- (NSURL *) thumbUrl {
	return [[self class] urlForImageInDirectory:self.directory andUuidString:self.imageUuid];
}

+ (NSSet *) keyPathsForValuesAffectingThumbUrl {
	return [NSSet setWithObjects:@"directory", @"imageUuid", nil];
}

/**
 * Removes this thumbnail's on-disk representation before it is about to be
 * torn down.
 */
- (void) prepareForDeletion {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *err = nil;
	
	[super prepareForDeletion];
	
	// Try to delete the thumbnail's file from disk
	if([fm removeItemAtURL:self.thumbUrl error:&err] == NO) {
		DDLogError(@"Couldn't remove thumb file %@ from disk: %@", self.thumbUrl, err);
	}
}

#pragma mark Helpers
/**
 * Generates a directory name.
 */
+ (NSString *) generateRandomDirectory {
	uint8_t bytes[1];
	SecRandomCopyBytes(kSecRandomDefault, 1, (uint8_t *) &bytes);
	
	return [NSString stringWithFormat:@"thumb-%02x", bytes[0]];
}

/**
 * Returns the full url of an image, given its directory and filename. The
 * thumbnail cache directory serves as the root of the cache, to which the
 * "directory" parameter is appended. The filename is the image uuid, plus the 
 * extension "jp2."
 */
+ (NSURL *) urlForImageInDirectory:(NSString *) dir andUuidString:(NSString *) uuid {
	// get the url of the cache itself	
	NSURL *cacheUrl = [TSGroupContainerHelper sharedInstance].caches;
	cacheUrl = [cacheUrl URLByAppendingPathComponent:@"TSThumbCache" isDirectory:YES];
	
	// append the directory and filename
	NSURL *imageUrl = [cacheUrl URLByAppendingPathComponent:dir
												isDirectory:YES];
	
	NSString *filename = [uuid stringByAppendingPathExtension:@"jp2"];
	imageUrl = [imageUrl URLByAppendingPathComponent:filename isDirectory:NO];
	
	return imageUrl;
}

@end
