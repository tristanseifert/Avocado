// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryExportService.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class NSObject;

@interface TSLibraryExportServiceID : NSManagedObjectID {}
@end

@interface _TSLibraryExportService : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryExportServiceID *objectID;

@property (nonatomic, strong, nullable) NSString* instanceUuid;

@property (nonatomic, strong, nullable) NSString* plugin;

@property (nonatomic, strong, nullable) id settings;

@property (nonatomic, strong, nullable) NSString* title;

@end

@interface _TSLibraryExportService (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveInstanceUuid;
- (void)setPrimitiveInstanceUuid:(NSString*)value;

- (NSString*)primitivePlugin;
- (void)setPrimitivePlugin:(NSString*)value;

- (id)primitiveSettings;
- (void)setPrimitiveSettings:(id)value;

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

@end

@interface TSLibraryExportServiceAttributes: NSObject 
+ (NSString *)instanceUuid;
+ (NSString *)plugin;
+ (NSString *)settings;
+ (NSString *)title;
@end

NS_ASSUME_NONNULL_END
