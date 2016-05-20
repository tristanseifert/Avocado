#import "_TSLibraryImage.h"

/// current adjustment dictionary version
extern const NSUInteger TSLibraryImageVersion;

#pragma mark Exposure Adjustment
/// exposure adjustments
extern NSString  * _Nonnull const TSAdjustmentKeyExposure;
/// adjustment of exposure, in EV [-5, 5]
extern NSString  * _Nonnull const TSAdjustmentKeyExposureEV;

#pragma mark Noise Reduction and Sharpening
/// Detail adjustment dictionary key
extern NSString * _Nonnull const TSAdjustmentKeyDetail;

/// noise reduction level [0, 1]
extern NSString * _Nonnull const TSAdjustmentKeyNoiseReductionLevel;
/// noise reduction sharpness [0, 1]
extern NSString * _Nonnull const TSAdjustmentKeyNoiseReductionSharpness;


/// Luminance sharpening amount [0, 1]
extern NSString * _Nonnull const TSAdjustmentKeySharpenLuminance;
/// Unsharp mask radius [0, 5]
extern NSString * _Nonnull const TSAdjustmentKeySharpenRadius;
/// Unsharp mask radius [0, 1]
extern NSString * _Nonnull const TSAdjustmentKeySharpenIntensity;
/// Median filter (bool)
extern NSString * _Nonnull const TSAdjustmentKeySharpenMedianFilter;


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
 * Adjustments applied on the image; each key represents a particular
 * filter, with a subdictionary containing all of its input values.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSDictionary<NSString *, id> *> *adjustments;

@end
