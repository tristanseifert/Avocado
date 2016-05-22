// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImageAdjustment.m instead.

#import "_TSLibraryImageAdjustment.h"

@implementation TSLibraryImageAdjustmentID
@end

@implementation _TSLibraryImageAdjustment

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
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

	if ([key isEqualToString:@"wValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"w"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"xValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"x"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"yValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"y"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"zValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"z"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic dateAdded;

@dynamic property;

@dynamic w;

- (double)wValue {
	NSNumber *result = [self w];
	return [result doubleValue];
}

- (void)setWValue:(double)value_ {
	[self setW:@(value_)];
}

- (double)primitiveWValue {
	NSNumber *result = [self primitiveW];
	return [result doubleValue];
}

- (void)setPrimitiveWValue:(double)value_ {
	[self setPrimitiveW:@(value_)];
}

@dynamic x;

- (double)xValue {
	NSNumber *result = [self x];
	return [result doubleValue];
}

- (void)setXValue:(double)value_ {
	[self setX:@(value_)];
}

- (double)primitiveXValue {
	NSNumber *result = [self primitiveX];
	return [result doubleValue];
}

- (void)setPrimitiveXValue:(double)value_ {
	[self setPrimitiveX:@(value_)];
}

@dynamic y;

- (double)yValue {
	NSNumber *result = [self y];
	return [result doubleValue];
}

- (void)setYValue:(double)value_ {
	[self setY:@(value_)];
}

- (double)primitiveYValue {
	NSNumber *result = [self primitiveY];
	return [result doubleValue];
}

- (void)setPrimitiveYValue:(double)value_ {
	[self setPrimitiveY:@(value_)];
}

@dynamic z;

- (double)zValue {
	NSNumber *result = [self z];
	return [result doubleValue];
}

- (void)setZValue:(double)value_ {
	[self setZ:@(value_)];
}

- (double)primitiveZValue {
	NSNumber *result = [self primitiveZ];
	return [result doubleValue];
}

- (void)setPrimitiveZValue:(double)value_ {
	[self setPrimitiveZ:@(value_)];
}

@dynamic image;

@end

@implementation TSLibraryImageAdjustmentAttributes 
+ (NSString *)dateAdded {
	return @"dateAdded";
}
+ (NSString *)property {
	return @"property";
}
+ (NSString *)w {
	return @"w";
}
+ (NSString *)x {
	return @"x";
}
+ (NSString *)y {
	return @"y";
}
+ (NSString *)z {
	return @"z";
}
@end

@implementation TSLibraryImageAdjustmentRelationships 
+ (NSString *)image {
	return @"image";
}
@end

