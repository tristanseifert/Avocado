// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImage.m instead.

#import "_TSLibraryImage.h"

const struct TSLibraryImageAttributes TSLibraryImageAttributes = {
	.dateImported = @"dateImported",
	.dateModified = @"dateModified",
	.dateShot = @"dateShot",
	.dayShot = @"dayShot",
	.fileType = @"fileType",
	.fileUrl = @"fileUrl",
	.metadata = @"metadata",
	.thumbData = @"thumbData",
};

const struct TSLibraryImageRelationships TSLibraryImageRelationships = {
	.adjustments = @"adjustments",
	.parentAlbums = @"parentAlbums",
	.tags = @"tags",
};

@implementation TSLibraryImageID
@end

@implementation _TSLibraryImage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
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

@dynamic thumbData;

@dynamic adjustments;

- (NSMutableOrderedSet*)adjustmentsSet {
	[self willAccessValueForKey:@"adjustments"];

	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"adjustments"];

	[self didAccessValueForKey:@"adjustments"];
	return result;
}

@dynamic parentAlbums;

- (NSMutableSet*)parentAlbumsSet {
	[self willAccessValueForKey:@"parentAlbums"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"parentAlbums"];

	[self didAccessValueForKey:@"parentAlbums"];
	return result;
}

@dynamic tags;

- (NSMutableSet*)tagsSet {
	[self willAccessValueForKey:@"tags"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"tags"];

	[self didAccessValueForKey:@"tags"];
	return result;
}

@end

@implementation _TSLibraryImage (AdjustmentsCoreDataGeneratedAccessors)
- (void)addAdjustments:(NSOrderedSet*)value_ {
	[self.adjustmentsSet unionOrderedSet:value_];
}
- (void)removeAdjustments:(NSOrderedSet*)value_ {
	[self.adjustmentsSet minusOrderedSet:value_];
}
- (void)addAdjustmentsObject:(TSLibraryImageAdjustment*)value_ {
	[self.adjustmentsSet addObject:value_];
}
- (void)removeAdjustmentsObject:(TSLibraryImageAdjustment*)value_ {
	[self.adjustmentsSet removeObject:value_];
}
- (void)insertObject:(TSLibraryImageAdjustment*)value inAdjustmentsAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"adjustments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self adjustments]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"adjustments"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"adjustments"];
}
- (void)removeObjectFromAdjustmentsAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"adjustments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self adjustments]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"adjustments"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"adjustments"];
}
- (void)insertAdjustments:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"adjustments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self adjustments]];
    [tmpOrderedSet insertObjects:value atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"adjustments"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"adjustments"];
}
- (void)removeAdjustmentsAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"adjustments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self adjustments]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"adjustments"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"adjustments"];
}
- (void)replaceObjectInAdjustmentsAtIndex:(NSUInteger)idx withObject:(TSLibraryImageAdjustment*)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"adjustments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self adjustments]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"adjustments"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"adjustments"];
}
- (void)replaceAdjustmentsAtIndexes:(NSIndexSet *)indexes withAdjustments:(NSArray *)value {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"adjustments"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self adjustments]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"adjustments"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"adjustments"];
}
@end

