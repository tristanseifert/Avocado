#import "_TSLibraryImageAdjustment.h"

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
@property (nonatomic) CIVector *vector3;


/**
 * Creates a dictionary, containing the values of every user-adjustable property
 * on this object.
 */
@property (nonatomic, readonly) NSDictionary *dictRepresentation;

/**
 * Restores the object's properties, given a dictionary of properties. This does
 * perform some validation of properties, but it is best to not place properties
 * in this dictionary that do not exist.
 *
 * @param dict A dictionary wherein each key/value pair corresponds to the value
 * a property on this object shall be set to.
 */
- (void) setValuesFromDictRepresentation:(NSDictionary<NSString *, id> *) dict;

@end
