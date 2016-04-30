#import "_TSLibraryImage.h"

/**
 * Enum holding the 'type' of the image, as determined by which rendering
 * pipeline it will use.
 *
 * "compressed" will load the image using NSImage, and render it normally.
 * "RAW" will utilize LibRAW to read and process the image.
 */
typedef NS_ENUM(int16_t, TSLibraryImageType) {
	TSLibraryImageCompressed = 0x0001,
	TSLibraryImageRaw = 0x0002,
};

@interface TSLibraryImage : _TSLibraryImage {}

/**
 * Key/value dictionary containing the image metadata.
 */
@property (nonatomic) NSDictionary *metadata;

/**
 * URL of the source file.
 */
@property (nonatomic) NSURL *fileUrl;

/**
 * Kind of image. See the `TSLibraryImageType` description for more info.
 */
@property (atomic) TSLibraryImageType fileTypeValue;

@end
