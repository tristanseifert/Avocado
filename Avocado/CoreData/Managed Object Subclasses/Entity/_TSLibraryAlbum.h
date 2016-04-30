// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryAlbum.h instead.

@import CoreData;

extern const struct TSLibraryAlbumAttributes {
	__unsafe_unretained NSString *created;
	__unsafe_unretained NSString *summary;
	__unsafe_unretained NSString *title;
} TSLibraryAlbumAttributes;

extern const struct TSLibraryAlbumRelationships {
	__unsafe_unretained NSString *images;
	__unsafe_unretained NSString *parentCollection;
} TSLibraryAlbumRelationships;

@class TSLibraryImage;
@class TSLibraryAlbumCollection;

@interface TSLibraryAlbumID : NSManagedObjectID {}
@end

@interface _TSLibraryAlbum : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryAlbumID* objectID;

@property (nonatomic, strong) NSDate* created;

//- (BOOL)validateCreated:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* summary;

//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* title;

//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSOrderedSet *images;

- (NSMutableOrderedSet*)imagesSet;

@property (nonatomic, strong) TSLibraryAlbumCollection *parentCollection;

//- (BOOL)validateParentCollection:(id*)value_ error:(NSError**)error_;

@end

@interface _TSLibraryAlbum (ImagesCoreDataGeneratedAccessors)
- (void)addImages:(NSOrderedSet*)value_;
- (void)removeImages:(NSOrderedSet*)value_;
- (void)addImagesObject:(TSLibraryImage*)value_;
- (void)removeImagesObject:(TSLibraryImage*)value_;

- (void)insertObject:(TSLibraryImage*)value inImagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromImagesAtIndex:(NSUInteger)idx;
- (void)insertImages:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeImagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInImagesAtIndex:(NSUInteger)idx withObject:(TSLibraryImage*)value;
- (void)replaceImagesAtIndexes:(NSIndexSet *)indexes withImages:(NSArray *)values;

@end

@interface _TSLibraryAlbum (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveCreated;
- (void)setPrimitiveCreated:(NSDate*)value;

- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

- (NSMutableOrderedSet*)primitiveImages;
- (void)setPrimitiveImages:(NSMutableOrderedSet*)value;

- (TSLibraryAlbumCollection*)primitiveParentCollection;
- (void)setPrimitiveParentCollection:(TSLibraryAlbumCollection*)value;

@end
