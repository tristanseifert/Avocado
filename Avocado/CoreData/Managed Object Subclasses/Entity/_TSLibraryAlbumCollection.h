// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryAlbumCollection.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class TSLibraryAlbum;
@class TSLibraryAlbumCollection;
@class TSLibraryAlbumCollection;

@interface TSLibraryAlbumCollectionID : NSManagedObjectID {}
@end

@interface _TSLibraryAlbumCollection : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryAlbumCollectionID *objectID;

@property (nonatomic, strong, nullable) NSString* title;

@property (nonatomic, strong, nullable) NSOrderedSet<TSLibraryAlbum*> *albums;
- (nullable NSMutableOrderedSet<TSLibraryAlbum*>*)albumsSet;

@property (nonatomic, strong, nullable) NSOrderedSet<TSLibraryAlbumCollection*> *collections;
- (nullable NSMutableOrderedSet<TSLibraryAlbumCollection*>*)collectionsSet;

@property (nonatomic, strong, nullable) TSLibraryAlbumCollection *parentCollection;

@end

@interface _TSLibraryAlbumCollection (AlbumsCoreDataGeneratedAccessors)
- (void)addAlbums:(NSOrderedSet<TSLibraryAlbum*>*)value_;
- (void)removeAlbums:(NSOrderedSet<TSLibraryAlbum*>*)value_;
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
- (void)addCollections:(NSOrderedSet<TSLibraryAlbumCollection*>*)value_;
- (void)removeCollections:(NSOrderedSet<TSLibraryAlbumCollection*>*)value_;
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

- (NSMutableOrderedSet<TSLibraryAlbum*>*)primitiveAlbums;
- (void)setPrimitiveAlbums:(NSMutableOrderedSet<TSLibraryAlbum*>*)value;

- (NSMutableOrderedSet<TSLibraryAlbumCollection*>*)primitiveCollections;
- (void)setPrimitiveCollections:(NSMutableOrderedSet<TSLibraryAlbumCollection*>*)value;

- (TSLibraryAlbumCollection*)primitiveParentCollection;
- (void)setPrimitiveParentCollection:(TSLibraryAlbumCollection*)value;

@end

@interface TSLibraryAlbumCollectionAttributes: NSObject 
+ (NSString *)title;
@end

@interface TSLibraryAlbumCollectionRelationships: NSObject
+ (NSString *)albums;
+ (NSString *)collections;
+ (NSString *)parentCollection;
@end

NS_ASSUME_NONNULL_END
