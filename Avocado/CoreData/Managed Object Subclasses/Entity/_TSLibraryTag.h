// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryTag.h instead.

@import CoreData;

extern const struct TSLibraryTagAttributes {
	__unsafe_unretained NSString *title;
} TSLibraryTagAttributes;

extern const struct TSLibraryTagRelationships {
	__unsafe_unretained NSString *images;
} TSLibraryTagRelationships;

@class TSLibraryImage;

@interface TSLibraryTagID : NSManagedObjectID {}
@end

@interface _TSLibraryTag : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryTagID* objectID;

@property (nonatomic, strong) NSString* title;

//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *images;

- (NSMutableSet*)imagesSet;

@end

@interface _TSLibraryTag (ImagesCoreDataGeneratedAccessors)
- (void)addImages:(NSSet*)value_;
- (void)removeImages:(NSSet*)value_;
- (void)addImagesObject:(TSLibraryImage*)value_;
- (void)removeImagesObject:(TSLibraryImage*)value_;

@end

@interface _TSLibraryTag (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

- (NSMutableSet*)primitiveImages;
- (void)setPrimitiveImages:(NSMutableSet*)value;

@end
