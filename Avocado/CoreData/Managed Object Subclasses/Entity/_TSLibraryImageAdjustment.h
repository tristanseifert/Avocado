// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImageAdjustment.h instead.

@import CoreData;

extern const struct TSLibraryImageAdjustmentAttributes {
	__unsafe_unretained NSString *delta;
	__unsafe_unretained NSString *key;
} TSLibraryImageAdjustmentAttributes;

extern const struct TSLibraryImageAdjustmentRelationships {
	__unsafe_unretained NSString *image;
} TSLibraryImageAdjustmentRelationships;

@class TSLibraryImage;

@interface TSLibraryImageAdjustmentID : NSManagedObjectID {}
@end

@interface _TSLibraryImageAdjustment : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryImageAdjustmentID* objectID;

@property (nonatomic, strong) NSNumber* delta;

@property (atomic) double deltaValue;
- (double)deltaValue;
- (void)setDeltaValue:(double)value_;

//- (BOOL)validateDelta:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* key;

//- (BOOL)validateKey:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) TSLibraryImage *image;

//- (BOOL)validateImage:(id*)value_ error:(NSError**)error_;

@end

@interface _TSLibraryImageAdjustment (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveDelta;
- (void)setPrimitiveDelta:(NSNumber*)value;

- (double)primitiveDeltaValue;
- (void)setPrimitiveDeltaValue:(double)value_;

- (NSString*)primitiveKey;
- (void)setPrimitiveKey:(NSString*)value;

- (TSLibraryImage*)primitiveImage;
- (void)setPrimitiveImage:(TSLibraryImage*)value;

@end
