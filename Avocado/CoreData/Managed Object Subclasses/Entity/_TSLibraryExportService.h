// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryExportService.h instead.

@import CoreData;

extern const struct TSLibraryExportServiceAttributes {
	__unsafe_unretained NSString *instanceUuid;
	__unsafe_unretained NSString *plugin;
	__unsafe_unretained NSString *settings;
	__unsafe_unretained NSString *title;
} TSLibraryExportServiceAttributes;

@class NSObject;

@interface TSLibraryExportServiceID : NSManagedObjectID {}
@end

@interface _TSLibraryExportService : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryExportServiceID* objectID;

@property (nonatomic, strong) NSString* instanceUuid;

//- (BOOL)validateInstanceUuid:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* plugin;

//- (BOOL)validatePlugin:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id settings;

//- (BOOL)validateSettings:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* title;

//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;

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
