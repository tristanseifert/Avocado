// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryAlbum.m instead.

#import "_TSLibraryAlbum.h"

const struct TSLibraryAlbumAttributes TSLibraryAlbumAttributes = {
	.created = @"created",
	.summary = @"summary",
	.title = @"title",
};

const struct TSLibraryAlbumRelationships TSLibraryAlbumRelationships = {
	.images = @"images",
	.parentCollection = @"parentCollection",
};

@implementation TSLibraryAlbumID
@end

@implementation _TSLibraryAlbum

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Album";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Album" inManagedObjectContext:moc_];
}

- (TSLibraryAlbumID*)objectID {
	return (TSLibraryAlbumID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic created;

@dynamic summary;

@dynamic title;

@dynamic images;

- (NSMutableOrderedSet*)imagesSet {
	[self willAccessValueForKey:@"images"];

	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"images"];

	[self didAccessValueForKey:@"images"];
	return result;
}

@dynamic parentCollection;

@end

@implementation _TSLibraryAlbum (ImagesCoreDataGeneratedAccessors)
- (void)addImages:(NSOrderedSet*)value_ {
	[self.imagesSet unionOrderedSet:value_];
}
- (void)removeImages:(NSOrderedSet*)value_ {
	[self.imagesSet minusOrderedSet:value_];
}
- (void)addImagesObject:(TSLibraryImage*)value_ {
	[self.imagesSet addObject:value_];
}
- (void)removeImagesObject:(TSLibraryImage*)value_ {
	[self.imagesSet removeObject:value_];
}
- (void)insertObject:(TSLibraryImage*)value inImagesAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"images"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self images]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"images"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"images"];
}
- (void)removeObjectFromImagesAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"images"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self images]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"images"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"images"];
}
- (void)insertImages:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"images"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self images]];
    [tmpOrderedSet insertObjects:value atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"images"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"images"];
}
- (void)removeImagesAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"images"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self images]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"images"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"images"];
}
- (void)replaceObjectInImagesAtIndex:(NSUInteger)idx withObject:(TSLibraryImage*)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"images"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self images]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"images"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"images"];
}
- (void)replaceImagesAtIndexes:(NSIndexSet *)indexes withImages:(NSArray *)value {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"images"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self images]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"images"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"images"];
}
@end

