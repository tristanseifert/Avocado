// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryAlbumCollection.m instead.

#import "_TSLibraryAlbumCollection.h"

const struct TSLibraryAlbumCollectionAttributes TSLibraryAlbumCollectionAttributes = {
	.title = @"title",
};

const struct TSLibraryAlbumCollectionRelationships TSLibraryAlbumCollectionRelationships = {
	.albums = @"albums",
	.collections = @"collections",
	.parentCollection = @"parentCollection",
};

@implementation TSLibraryAlbumCollectionID
@end

@implementation _TSLibraryAlbumCollection

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"AlbumCollection" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"AlbumCollection";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"AlbumCollection" inManagedObjectContext:moc_];
}

- (TSLibraryAlbumCollectionID*)objectID {
	return (TSLibraryAlbumCollectionID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic title;

@dynamic albums;

- (NSMutableOrderedSet*)albumsSet {
	[self willAccessValueForKey:@"albums"];

	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"albums"];

	[self didAccessValueForKey:@"albums"];
	return result;
}

@dynamic collections;

- (NSMutableOrderedSet*)collectionsSet {
	[self willAccessValueForKey:@"collections"];

	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"collections"];

	[self didAccessValueForKey:@"collections"];
	return result;
}

@dynamic parentCollection;

@end

@implementation _TSLibraryAlbumCollection (AlbumsCoreDataGeneratedAccessors)
- (void)addAlbums:(NSOrderedSet*)value_ {
	[self.albumsSet unionOrderedSet:value_];
}
- (void)removeAlbums:(NSOrderedSet*)value_ {
	[self.albumsSet minusOrderedSet:value_];
}
- (void)addAlbumsObject:(TSLibraryAlbum*)value_ {
	[self.albumsSet addObject:value_];
}
- (void)removeAlbumsObject:(TSLibraryAlbum*)value_ {
	[self.albumsSet removeObject:value_];
}
- (void)insertObject:(TSLibraryAlbum*)value inAlbumsAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"albums"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self albums]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"albums"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"albums"];
}
- (void)removeObjectFromAlbumsAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"albums"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self albums]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"albums"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"albums"];
}
- (void)insertAlbums:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"albums"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self albums]];
    [tmpOrderedSet insertObjects:value atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"albums"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"albums"];
}
- (void)removeAlbumsAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"albums"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self albums]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"albums"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"albums"];
}
- (void)replaceObjectInAlbumsAtIndex:(NSUInteger)idx withObject:(TSLibraryAlbum*)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"albums"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self albums]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"albums"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"albums"];
}
- (void)replaceAlbumsAtIndexes:(NSIndexSet *)indexes withAlbums:(NSArray *)value {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"albums"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self albums]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"albums"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"albums"];
}
@end

@implementation _TSLibraryAlbumCollection (CollectionsCoreDataGeneratedAccessors)
- (void)addCollections:(NSOrderedSet*)value_ {
	[self.collectionsSet unionOrderedSet:value_];
}
- (void)removeCollections:(NSOrderedSet*)value_ {
	[self.collectionsSet minusOrderedSet:value_];
}
- (void)addCollectionsObject:(TSLibraryAlbumCollection*)value_ {
	[self.collectionsSet addObject:value_];
}
- (void)removeCollectionsObject:(TSLibraryAlbumCollection*)value_ {
	[self.collectionsSet removeObject:value_];
}
- (void)insertObject:(TSLibraryAlbumCollection*)value inCollectionsAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"collections"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self collections]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"collections"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"collections"];
}
- (void)removeObjectFromCollectionsAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"collections"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self collections]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"collections"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"collections"];
}
- (void)insertCollections:(NSArray *)value atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"collections"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self collections]];
    [tmpOrderedSet insertObjects:value atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"collections"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"collections"];
}
- (void)removeCollectionsAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"collections"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self collections]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"collections"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"collections"];
}
- (void)replaceObjectInCollectionsAtIndex:(NSUInteger)idx withObject:(TSLibraryAlbumCollection*)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"collections"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self collections]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"collections"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"collections"];
}
- (void)replaceCollectionsAtIndexes:(NSIndexSet *)indexes withCollections:(NSArray *)value {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"collections"];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self collections]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:@"collections"];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"collections"];
}
@end

