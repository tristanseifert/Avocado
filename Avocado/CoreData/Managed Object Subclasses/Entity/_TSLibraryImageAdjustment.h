// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImageAdjustment.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class TSLibraryImage;

@interface TSLibraryImageAdjustmentID : NSManagedObjectID {}
@end

@interface _TSLibraryImageAdjustment : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryImageAdjustmentID *objectID;

@property (nonatomic, strong, nullable) NSNumber* delta;

@property (atomic) double deltaValue;
- (double)deltaValue;
- (void)setDeltaValue:(double)value_;

@property (nonatomic, strong, nullable) NSString* key;

@property (nonatomic, strong, nullable) TSLibraryImage *image;

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

@interface TSLibraryImageAdjustmentAttributes: NSObject 
+ (NSString *)delta;
+ (NSString *)key;
@end

@interface TSLibraryImageAdjustmentRelationships: NSObject
+ (NSString *)image;
@end

NS_ASSUME_NONNULL_END
