// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImage.h instead.

@import CoreData;

extern const struct TSLibraryImageAttributes {
	__unsafe_unretained NSString *fileUrl;
	__unsafe_unretained NSString *metadata;
	__unsafe_unretained NSString *thumbData;
} TSLibraryImageAttributes;

extern const struct TSLibraryImageRelationships {
	__unsafe_unretained NSString *adjustments;
	__unsafe_unretained NSString *parentAlbums;
	__unsafe_unretained NSString *tags;
} TSLibraryImageRelationships;

@class TSLibraryImageAdjustment;
@class TSLibraryAlbum;
@class TSLibraryTag;

@class NSObject;

@class NSObject;

@interface TSLibraryImageID : NSManagedObjectID {}
@end

@interface _TSLibraryImage : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryImageID* objectID;

@property (nonatomic, strong) id fileUrl;

//- (BOOL)validateFileUrl:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id metadata;

//- (BOOL)validateMetadata:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSData* thumbData;

//- (BOOL)validateThumbData:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSOrderedSet *adjustments;

- (NSMutableOrderedSet*)adjustmentsSet;

@property (nonatomic, strong) NSSet *parentAlbums;

- (NSMutableSet*)parentAlbumsSet;

@property (nonatomic, strong) NSSet *tags;

- (NSMutableSet*)tagsSet;

@end

@interface _TSLibraryImage (AdjustmentsCoreDataGeneratedAccessors)
- (void)addAdjustments:(NSOrderedSet*)value_;
- (void)removeAdjustments:(NSOrderedSet*)value_;
- (void)addAdjustmentsObject:(TSLibraryImageAdjustment*)value_;
- (void)removeAdjustmentsObject:(TSLibraryImageAdjustment*)value_;

- (void)insertObject:(TSLibraryImageAdjustment*)value inAdjustmentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAdjustmentsAtIndex:(NSUInteger)idx;
- (void)insertAdjustments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAdjustmentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAdjustmentsAtIndex:(NSUInteger)idx withObject:(TSLibraryImageAdjustment*)value;
- (void)replaceAdjustmentsAtIndexes:(NSIndexSet *)indexes withAdjustments:(NSArray *)values;

@end

@interface _TSLibraryImage (ParentAlbumsCoreDataGeneratedAccessors)
- (void)addParentAlbums:(NSSet*)value_;
- (void)removeParentAlbums:(NSSet*)value_;
- (void)addParentAlbumsObject:(TSLibraryAlbum*)value_;
- (void)removeParentAlbumsObject:(TSLibraryAlbum*)value_;

@end

@interface _TSLibraryImage (TagsCoreDataGeneratedAccessors)
- (void)addTags:(NSSet*)value_;
- (void)removeTags:(NSSet*)value_;
- (void)addTagsObject:(TSLibraryTag*)value_;
- (void)removeTagsObject:(TSLibraryTag*)value_;

@end

@interface _TSLibraryImage (CoreDataGeneratedPrimitiveAccessors)

- (id)primitiveFileUrl;
- (void)setPrimitiveFileUrl:(id)value;

- (id)primitiveMetadata;
- (void)setPrimitiveMetadata:(id)value;

- (NSData*)primitiveThumbData;
- (void)setPrimitiveThumbData:(NSData*)value;

- (NSMutableOrderedSet*)primitiveAdjustments;
- (void)setPrimitiveAdjustments:(NSMutableOrderedSet*)value;

- (NSMutableSet*)primitiveParentAlbums;
- (void)setPrimitiveParentAlbums:(NSMutableSet*)value;

- (NSMutableSet*)primitiveTags;
- (void)setPrimitiveTags:(NSMutableSet*)value;

@end
