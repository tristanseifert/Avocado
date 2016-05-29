// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSThumbnail.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface TSThumbnailID : NSManagedObjectID {}
@end

@interface _TSThumbnail : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSThumbnailID *objectID;

@property (nonatomic, strong, nullable) NSDate* dateAdded;

@property (nonatomic, strong, nullable) NSDate* dateLastAccessed;

@property (nonatomic, strong, nullable) NSString* directory;

@property (nonatomic, strong, nullable) NSString* filename;

@property (nonatomic, strong, nullable) NSString* imageUuid;

@end

@interface _TSThumbnail (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveDateAdded;
- (void)setPrimitiveDateAdded:(NSDate*)value;

- (NSDate*)primitiveDateLastAccessed;
- (void)setPrimitiveDateLastAccessed:(NSDate*)value;

- (NSString*)primitiveDirectory;
- (void)setPrimitiveDirectory:(NSString*)value;

- (NSString*)primitiveFilename;
- (void)setPrimitiveFilename:(NSString*)value;

- (NSString*)primitiveImageUuid;
- (void)setPrimitiveImageUuid:(NSString*)value;

@end

@interface TSThumbnailAttributes: NSObject 
+ (NSString *)dateAdded;
+ (NSString *)dateLastAccessed;
+ (NSString *)directory;
+ (NSString *)filename;
+ (NSString *)imageUuid;
@end

NS_ASSUME_NONNULL_END
