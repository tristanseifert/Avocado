// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImageCorrectionData.m instead.

#import "_TSLibraryImageCorrectionData.h"

@implementation TSLibraryImageCorrectionDataID
@end

@implementation _TSLibraryImageCorrectionData

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ImageCorrectionData" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ImageCorrectionData";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ImageCorrectionData" inManagedObjectContext:moc_];
}

- (TSLibraryImageCorrectionDataID*)objectID {
	return (TSLibraryImageCorrectionDataID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"enabledValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"enabled"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic cameraData;

@dynamic enabled;

- (int16_t)enabledValue {
	NSNumber *result = [self enabled];
	return [result shortValue];
}

- (void)setEnabledValue:(int16_t)value_ {
	[self setEnabled:@(value_)];
}

- (int16_t)primitiveEnabledValue {
	NSNumber *result = [self primitiveEnabled];
	return [result shortValue];
}

- (void)setPrimitiveEnabledValue:(int16_t)value_ {
	[self setPrimitiveEnabled:@(value_)];
}

@dynamic lensData;

@dynamic image;

@end

@implementation TSLibraryImageCorrectionDataAttributes 
+ (NSString *)cameraData {
	return @"cameraData";
}
+ (NSString *)enabled {
	return @"enabled";
}
+ (NSString *)lensData {
	return @"lensData";
}
@end

@implementation TSLibraryImageCorrectionDataRelationships 
+ (NSString *)image {
	return @"image";
}
@end

