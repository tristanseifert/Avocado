#import "_TSLibraryImage.h"

@interface TSLibraryImage : _TSLibraryImage {}

/**
 * Key/value dictionary containing the image metadata.
 */
@property (nonatomic) NSDictionary *metadata;

/**
 * URL of the source file.
 */
@property (nonatomic) NSURL *fileUrl;

@end
