// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryAlbumCollection.h instead.

@import CoreData;

extern const struct TSLibraryAlbumCollectionAttributes {
	__unsafe_unretained NSString *title;
} TSLibraryAlbumCollectionAttributes;

extern const struct TSLibraryAlbumCollectionRelationships {
	__unsafe_unretained NSString *albums;
	__unsafe_unretained NSString *collections;
	__unsafe_unretained NSString *parentCollection;
} TSLibraryAlbumCollectionRelationships;

@class TSLibraryAlbum;
@class TSLibraryAlbumCollection;
@class TSLibraryAlbumCollection;

@interface TSLibraryAlbumCollectionID : NSManagedObjectID {}
@end

@interface _TSLibraryAlbumCollection : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryAlbumCollectionID* objectID;

@property (nonatomic, strong) NSString* title;

//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSOrderedSet *albums;

- (NSMutableOrderedSet*)albumsSet;

@property (nonatomic, strong) NSOrderedSet *collections;

- (NSMutableOrderedSet*)collectionsSet;

@property (nonatomic, strong) TSLibraryAlbumCollection *parentCollection;

//- (BOOL)validateParentCollection:(id*)value_ error:(NSError**)error_;

@end

@interface _TSLibraryAlbumCollection (AlbumsCoreDataGeneratedAccessors)
- (void)addAlbums:(NSOrderedSet*)value_;
- (void)removeAlbums:(NSOrderedSet*)value_;
- (void)addAlbumsObject:(TSLibraryAlbum*)value_;
- (void)removeAlbumsObject:(TSLibraryAlbum*)value_;

- (void)insertObject:(TSLibraryAlbum*)value inAlbumsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAlbumsAtIndex:(NSUInteger)idx;
- (void)insertAlbums:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAlbumsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAlbumsAtIndex:(NSUInteger)idx withObject:(TSLibraryAlbum*)value;
- (void)replaceAlbumsAtIndexes:(NSIndexSet *)indexes withAlbums:(NSArray *)values;

@end

@interface _TSLibraryAlbumCollection (CollectionsCoreDataGeneratedAccessors)
- (void)addCollections:(NSOrderedSet*)value_;
- (void)removeCollections:(NSOrderedSet*)value_;
- (void)addCollectionsObject:(TSLibraryAlbumCollection*)value_;
- (void)removeCollectionsObject:(TSLibraryAlbumCollection*)value_;

- (void)insertObject:(TSLibraryAlbumCollection*)value inCollectionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCollectionsAtIndex:(NSUInteger)idx;
- (void)insertCollections:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCollectionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCollectionsAtIndex:(NSUInteger)idx withObject:(TSLibraryAlbumCollection*)value;
- (void)replaceCollectionsAtIndexes:(NSIndexSet *)indexes withCollections:(NSArray *)values;

@end

@interface _TSLibraryAlbumCollection (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

- (NSMutableOrderedSet*)primitiveAlbums;
- (void)setPrimitiveAlbums:(NSMutableOrderedSet*)value;

- (NSMutableOrderedSet*)primitiveCollections;
- (void)setPrimitiveCollections:(NSMutableOrderedSet*)value;

- (TSLibraryAlbumCollection*)primitiveParentCollection;
- (void)setPrimitiveParentCollection:(TSLibraryAlbumCollection*)value;

@end
