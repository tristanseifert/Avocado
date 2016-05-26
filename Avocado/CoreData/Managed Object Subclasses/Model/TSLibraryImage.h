#import "_TSLibraryImage.h"
#import "TSLibraryImageAdjustmentsProxy.h"

#pragma mark Metadata Keys
/// raw EXIF data
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyEXIF;

/// camera maker, as specified in the EXIF data
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyCameraMaker;
/// camera model, as specified in the EXIF data
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyCameraModel;

/// lens maker, as specified in the EXIF data
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyLensMaker;
/// lens model, as specified in the EXIF data
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyLensModel;
/// a human-readable lens specification
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyLensSpecification;
/// focal length at which the lens was used
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyLensFocalLength;

/// exposure compensation set for the shot
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyExposureCompensation;
/// ISO used for the shot
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyISO;
/// shutter speed used for the shot
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyShutter;
/// aperture used for the shot
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyAperture;

/// Camera-specified 'author' field
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyAuthor;
/// Camera-specified description field
extern NSString  * _Nonnull const TSLibraryImageMetadataKeyDescription;

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

/**
 * Various rotation possibilities for the image.
 */
typedef NS_ENUM(short, TSLibraryImageRotation) {
	TSLibraryImageRotationUnknown = -1,
	
	TSLibraryImageNoRotation = 0,
	TSLibraryImage180Degrees,		// 180°
	TSLibraryImage90DegreesCW,		// 90°, clockwise
	TSLibraryImage90DegreesCCW,		// 90°, counterclockwise
};

@interface TSLibraryImage : _TSLibraryImage {}

/**
 * Key/value dictionary containing the image metadata.
 */
@property (nonatomic) NSDictionary * _Nonnull metadata;

/**
 * URL of the source file.
 */
@property (nonatomic) NSURL * _Nonnull fileUrl;

/**
 * Kind of image. See the `TSLibraryImageType` description for more info.
 */
@property (atomic) TSLibraryImageType fileTypeValue;

/**
 * Time interval since the reference date, indicating when this image was
 * shot; however, the time component is set to 00:00:00.000 for easy sorting
 * and uniquing.
 */
@property (atomic) NSTimeInterval dayShotValue;

/**
 * The pixel size of the full image. This does NOT take into account rotation.
 */
@property (nonatomic, readwrite) NSSize imageSize;

/**
 * The actual size of the full image, taking into account rotation.
 */
@property (nonatomic, readonly) NSSize rotatedImageSize;

/**
 * Determines whether the image is rotated.
 */
@property (nonatomic, readonly) TSLibraryImageRotation rotation;

/**
 * Adjustments proxy; use KVC to get the adjustment objects for any of the
 * `TSAdjustmentKey…` adjustments.
 */
@property (nonatomic, readonly) TSLibraryImageAdjustmentsProxy* _Nonnull adjustments;

@end
