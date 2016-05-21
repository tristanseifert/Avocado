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

@property (nonatomic, strong, nullable) NSString* property;

@property (nonatomic, strong, nullable) NSNumber* w;

@property (atomic) double wValue;
- (double)wValue;
- (void)setWValue:(double)value_;

@property (nonatomic, strong, nullable) NSNumber* x;

@property (atomic) double xValue;
- (double)xValue;
- (void)setXValue:(double)value_;

@property (nonatomic, strong, nullable) NSNumber* y;

@property (atomic) double yValue;
- (double)yValue;
- (void)setYValue:(double)value_;

@property (nonatomic, strong, nullable) NSNumber* z;

@property (atomic) double zValue;
- (double)zValue;
- (void)setZValue:(double)value_;

@property (nonatomic, strong, nullable) TSLibraryImage *image;

@end

@interface _TSLibraryImageAdjustment (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveProperty;
- (void)setPrimitiveProperty:(NSString*)value;

- (NSNumber*)primitiveW;
- (void)setPrimitiveW:(NSNumber*)value;

- (double)primitiveWValue;
- (void)setPrimitiveWValue:(double)value_;

- (NSNumber*)primitiveX;
- (void)setPrimitiveX:(NSNumber*)value;

- (double)primitiveXValue;
- (void)setPrimitiveXValue:(double)value_;

- (NSNumber*)primitiveY;
- (void)setPrimitiveY:(NSNumber*)value;

- (double)primitiveYValue;
- (void)setPrimitiveYValue:(double)value_;

- (NSNumber*)primitiveZ;
- (void)setPrimitiveZ:(NSNumber*)value;

- (double)primitiveZValue;
- (void)setPrimitiveZValue:(double)value_;

- (TSLibraryImage*)primitiveImage;
- (void)setPrimitiveImage:(TSLibraryImage*)value;

@end

@interface TSLibraryImageAdjustmentAttributes: NSObject 
+ (NSString *)property;
+ (NSString *)w;
+ (NSString *)x;
+ (NSString *)y;
+ (NSString *)z;
@end

@interface TSLibraryImageAdjustmentRelationships: NSObject
+ (NSString *)image;
@end

NS_ASSUME_NONNULL_END
