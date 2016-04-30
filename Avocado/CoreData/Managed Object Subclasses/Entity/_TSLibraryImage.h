// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImage.h instead.

@import CoreData;

extern const struct TSLibraryImageAttributes {
	__unsafe_unretained NSString *fileUrl;
	__unsafe_unretained NSString *thumbData;
} TSLibraryImageAttributes;

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

@property (nonatomic, strong) NSData* thumbData;

//- (BOOL)validateThumbData:(id*)value_ error:(NSError**)error_;

@end

@interface _TSLibraryImage (CoreDataGeneratedPrimitiveAccessors)

- (id)primitiveFileUrl;
- (void)setPrimitiveFileUrl:(id)value;

- (NSData*)primitiveThumbData;
- (void)setPrimitiveThumbData:(NSData*)value;

@end
