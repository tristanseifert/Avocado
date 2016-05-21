// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImage.m instead.

#import "_TSLibraryImage.h"

@implementation TSLibraryImageID
@end

@implementation _TSLibraryImage

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Image";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Image" inManagedObjectContext:moc_];
}

- (TSLibraryImageID*)objectID {
	return (TSLibraryImageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"dayShotValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"dayShot"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"fileTypeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"fileType"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic dateImported;

@dynamic dateModified;

@dynamic dateShot;

@dynamic dayShot;

- (double)dayShotValue {
	NSNumber *result = [self dayShot];
	return [result doubleValue];
}

- (void)setDayShotValue:(double)value_ {
	[self setDayShot:@(value_)];
}

- (double)primitiveDayShotValue {
	NSNumber *result = [self primitiveDayShot];
	return [result doubleValue];
}

- (void)setPrimitiveDayShotValue:(double)value_ {
	[self setPrimitiveDayShot:@(value_)];
}

@dynamic fileType;

- (int16_t)fileTypeValue {
	NSNumber *result = [self fileType];
	return [result shortValue];
}

- (void)setFileTypeValue:(int16_t)value_ {
	[self setFileType:@(value_)];
}

- (int16_t)primitiveFileTypeValue {
	NSNumber *result = [self primitiveFileType];
	return [result shortValue];
}

- (void)setPrimitiveFileTypeValue:(int16_t)value_ {
	[self setPrimitiveFileType:@(value_)];
}

@dynamic fileUrl;

@dynamic metadata;

@dynamic pvtAdjustmentData;

@dynamic pvtImageSize;

@dynamic thumbUUID;

@dynamic uuid;

@dynamic parentAlbums;

- (NSMutableSet<TSLibraryAlbum*>*)parentAlbumsSet {
	[self willAccessValueForKey:@"parentAlbums"];

	NSMutableSet<TSLibraryAlbum*> *result = (NSMutableSet<TSLibraryAlbum*>*)[self mutableSetValueForKey:@"parentAlbums"];

	[self didAccessValueForKey:@"parentAlbums"];
	return result;
}

@dynamic pvtAdjustments;

- (NSMutableSet<TSLibraryImageAdjustment*>*)pvtAdjustmentsSet {
	[self willAccessValueForKey:@"pvtAdjustments"];

	NSMutableSet<TSLibraryImageAdjustment*> *result = (NSMutableSet<TSLibraryImageAdjustment*>*)[self mutableSetValueForKey:@"pvtAdjustments"];

	[self didAccessValueForKey:@"pvtAdjustments"];
	return result;
}

@dynamic tags;

- (NSMutableSet<TSLibraryTag*>*)tagsSet {
	[self willAccessValueForKey:@"tags"];

	NSMutableSet<TSLibraryTag*> *result = (NSMutableSet<TSLibraryTag*>*)[self mutableSetValueForKey:@"tags"];

	[self didAccessValueForKey:@"tags"];
	return result;
}

@end

@implementation TSLibraryImageAttributes 
+ (NSString *)dateImported {
	return @"dateImported";
}
+ (NSString *)dateModified {
	return @"dateModified";
}
+ (NSString *)dateShot {
	return @"dateShot";
}
+ (NSString *)dayShot {
	return @"dayShot";
}
+ (NSString *)fileType {
	return @"fileType";
}
+ (NSString *)fileUrl {
	return @"fileUrl";
}
+ (NSString *)metadata {
	return @"metadata";
}
+ (NSString *)pvtAdjustmentData {
	return @"pvtAdjustmentData";
}
+ (NSString *)pvtImageSize {
	return @"pvtImageSize";
}
+ (NSString *)thumbUUID {
	return @"thumbUUID";
}
+ (NSString *)uuid {
	return @"uuid";
}
@end

@implementation TSLibraryImageRelationships 
+ (NSString *)parentAlbums {
	return @"parentAlbums";
}
+ (NSString *)pvtAdjustments {
	return @"pvtAdjustments";
}
+ (NSString *)tags {
	return @"tags";
}
@end

