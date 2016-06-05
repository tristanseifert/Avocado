// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImageCorrectionData.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

#import "TSManagedObject.h"

NS_ASSUME_NONNULL_BEGIN

@class TSLibraryImage;

@interface TSLibraryImageCorrectionDataID : NSManagedObjectID {}
@end

@interface _TSLibraryImageCorrectionData : TSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryImageCorrectionDataID *objectID;

@property (nonatomic, strong, nullable) NSData* cameraData;

@property (nonatomic, strong, nullable) NSNumber* enabled;

@property (atomic) int16_t enabledValue;
- (int16_t)enabledValue;
- (void)setEnabledValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSData* lensData;

@property (nonatomic, strong, nullable) TSLibraryImage *image;

@end

@interface _TSLibraryImageCorrectionData (CoreDataGeneratedPrimitiveAccessors)

- (NSData*)primitiveCameraData;
- (void)setPrimitiveCameraData:(NSData*)value;

- (NSNumber*)primitiveEnabled;
- (void)setPrimitiveEnabled:(NSNumber*)value;

- (int16_t)primitiveEnabledValue;
- (void)setPrimitiveEnabledValue:(int16_t)value_;

- (NSData*)primitiveLensData;
- (void)setPrimitiveLensData:(NSData*)value;

- (TSLibraryImage*)primitiveImage;
- (void)setPrimitiveImage:(TSLibraryImage*)value;

@end

@interface TSLibraryImageCorrectionDataAttributes: NSObject 
+ (NSString *)cameraData;
+ (NSString *)enabled;
+ (NSString *)lensData;
@end

@interface TSLibraryImageCorrectionDataRelationships: NSObject
+ (NSString *)image;
@end

NS_ASSUME_NONNULL_END
