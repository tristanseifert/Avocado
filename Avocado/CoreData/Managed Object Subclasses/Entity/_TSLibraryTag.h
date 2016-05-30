// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryTag.h instead.

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

@interface TSLibraryTagID : NSManagedObjectID {}
@end

@interface _TSLibraryTag : TSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryTagID *objectID;

@property (nonatomic, strong, nullable) NSString* title;

@property (nonatomic, strong, nullable) NSSet<TSLibraryImage*> *images;
- (nullable NSMutableSet<TSLibraryImage*>*)imagesSet;

@end

@interface _TSLibraryTag (ImagesCoreDataGeneratedAccessors)
- (void)addImages:(NSSet<TSLibraryImage*>*)value_;
- (void)removeImages:(NSSet<TSLibraryImage*>*)value_;
- (void)addImagesObject:(TSLibraryImage*)value_;
- (void)removeImagesObject:(TSLibraryImage*)value_;

@end

@interface _TSLibraryTag (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

- (NSMutableSet<TSLibraryImage*>*)primitiveImages;
- (void)setPrimitiveImages:(NSMutableSet<TSLibraryImage*>*)value;

@end

@interface TSLibraryTagAttributes: NSObject 
+ (NSString *)title;
@end

@interface TSLibraryTagRelationships: NSObject
+ (NSString *)images;
@end

NS_ASSUME_NONNULL_END
