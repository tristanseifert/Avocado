#import "TSLibraryImageAdjustment.h"

#import <CoreImage/CoreImage.h>

@interface TSLibraryImageAdjustment ()

// Private interface goes here.

@end

@implementation TSLibraryImageAdjustment

/**
 * When first inserting the adjustment, set its timestamp.
 */
- (void) awakeFromInsert {
	[super awakeFromInsert];
	
	self.dateAdded = [NSDate new];
}

#pragma mark Computed Properties
/**
 * Creates a three component vector.
 */
- (CIVector *) vector3 {
	return [CIVector vectorWithX:self.x.doubleValue
							   Y:self.y.doubleValue
							   Z:self.z.doubleValue];
}

/**
 * Extracts the X, Y and Z components from the vector and sets it on the object.
 */
- (void) setVector3:(CIVector *) vector3 {
	self.x = @(vector3.X);
	self.y = @(vector3.Y);
	self.z = @(vector3.Z);
}

+ (NSSet *) keyPathsForValuesAffectingVector3 {
	return [NSSet setWithObjects:@"x", @"y", @"z", nil];
}


/**
 * Creates a dictionary, which can be copied and modified.
 */
- (NSDictionary *) dictRepresentation {
	return @{
		@"x": self.x,
		@"y": self.y,
		@"z": self.z,
		@"w": self.w
	};
}

+ (NSSet *) keyPathsForValuesAffectingDictRepresentation {
	return [NSSet setWithObjects:@"x", @"y", @"z", @"w", nil];
}

/**
 * Restores the object's properties, given a dictionary of properties. This does
 * not validate properties.
 *
 * @param dict A dictionary wherein each key/value pair corresponds to the value
 * a property on this object shall be set to.
 */
- (void) setValuesFromDictRepresentation:(NSDictionary<NSString *, id> *) dict {
	[dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
		[self setValue:value forKey:key];
	}];
}

@end
