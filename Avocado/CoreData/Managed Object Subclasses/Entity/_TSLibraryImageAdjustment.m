// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImageAdjustment.m instead.

#import "_TSLibraryImageAdjustment.h"

const struct TSLibraryImageAdjustmentAttributes TSLibraryImageAdjustmentAttributes = {
	.delta = @"delta",
	.key = @"key",
};

const struct TSLibraryImageAdjustmentRelationships TSLibraryImageAdjustmentRelationships = {
	.image = @"image",
};

@implementation TSLibraryImageAdjustmentID
@end

@implementation _TSLibraryImageAdjustment

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ImageAdjustment" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ImageAdjustment";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ImageAdjustment" inManagedObjectContext:moc_];
}

- (TSLibraryImageAdjustmentID*)objectID {
	return (TSLibraryImageAdjustmentID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"deltaValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"delta"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic delta;

- (double)deltaValue {
	NSNumber *result = [self delta];
	return [result doubleValue];
}

- (void)setDeltaValue:(double)value_ {
	[self setDelta:@(value_)];
}

- (double)primitiveDeltaValue {
	NSNumber *result = [self primitiveDelta];
	return [result doubleValue];
}

- (void)setPrimitiveDeltaValue:(double)value_ {
	[self setPrimitiveDelta:@(value_)];
}

@dynamic key;

@dynamic image;

@end

