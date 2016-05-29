#import "_TSThumbnail.h"

@interface TSThumbnail : _TSThumbnail

/**
 * Returns the full url to the thumbnail image.
 */
@property (nonatomic, readonly) NSURL *thumbUrl;


/**
 * Generates a directory name.
 */
+ (NSString *) generateRandomDirectory;

/**
 * Returns the full url of an image, given its directory and image uuid.
 */
+ (NSURL *) urlForImageInDirectory:(NSString *) dir andUuidString:(NSString *) uuid;

@end
