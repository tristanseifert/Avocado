#import "_TSLibraryImageAdjustment.h"

#pragma mark - Adjustment Keys
#pragma mark Exposure Adjustment
/// adjustment of exposure, in EV [-5, 5]
extern NSString  * _Nonnull const TSAdjustmentKeyExposureEV;

#pragma mark Tone Adjustment
/// saturation adjustment, [-1, 1]
extern NSString  * _Nonnull const TSAdjustmentKeyToneSaturation;
/// brightness adjustment, [-1, 1]
extern NSString  * _Nonnull const TSAdjustmentKeyToneBrightness;
/// contrast adjustment, [-1, 1]
extern NSString  * _Nonnull const TSAdjustmentKeyToneContrast;
/// vibrance adjustment, [-1, 1]
extern NSString  * _Nonnull const TSAdjustmentKeyToneVibrance;

#pragma mark Colour Adjustment
/*
 * Colour adjustments for eight different shifts; the X value is the additive
 * hue shift, whereas the Y and Z value are the saturation and lightness
 * multipliers, respectively.
 */
/// adjustments to red components
extern NSString  * _Nonnull const TSAdjustmentKeyColourRed;
/// adjustments to orange components
extern NSString  * _Nonnull const TSAdjustmentKeyColourOrange;
/// adjustments to yellow components
extern NSString  * _Nonnull const TSAdjustmentKeyColourYellow;
/// adjustments to green components
extern NSString  * _Nonnull const TSAdjustmentKeyColourGreen;
/// adjustments to aqua components
extern NSString  * _Nonnull const TSAdjustmentKeyColourAqua;
/// adjustments to blue components
extern NSString  * _Nonnull const TSAdjustmentKeyColourBlue;
/// adjustments to purple components
extern NSString  * _Nonnull const TSAdjustmentKeyColourPurple;
/// adjustments to magenta components
extern NSString  * _Nonnull const TSAdjustmentKeyColourMagenta;

#pragma mark Noise Reduction and Sharpening
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

@class CIVector;

/**
 * Represents an image adjustment object. Each image can be associated with
 * several of these for each distinct property. When the image is processed,
 * the adjustment with the latest (closest to current time) date will be
 * selected and used in rendering.
 */
@interface TSLibraryImageAdjustment : _TSLibraryImageAdjustment

/**
 * A computed propery that consists of a vector type built from the X, Y and Z
 * properties on this object.
 */
@property (nonatomic, nonnull) CIVector *vector3;


/**
 * Creates a dictionary, containing the values of every user-adjustable property
 * on this object.
 */
@property (nonatomic, readonly, nonnull) NSDictionary *dictRepresentation;

/**
 * Restores the object's properties, given a dictionary of properties. This does
 * perform some validation of properties, but it is best to not place properties
 * in this dictionary that do not exist.
 *
 * @param dict A dictionary wherein each key/value pair corresponds to the value
 * a property on this object shall be set to.
 */
- (void) setValuesFromDictRepresentation:(NSDictionary<NSString *, id> * _Nonnull) dict;

@end
