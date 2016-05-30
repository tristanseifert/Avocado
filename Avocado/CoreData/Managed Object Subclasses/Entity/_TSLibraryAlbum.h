// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryAlbum.h instead.

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
@class TSLibraryAlbumCollection;

@interface TSLibraryAlbumID : NSManagedObjectID {}
@end

@interface _TSLibraryAlbum : TSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryAlbumID *objectID;

@property (nonatomic, strong, nullable) NSDate* created;

@property (nonatomic, strong, nullable) NSString* summary;

@property (nonatomic, strong, nullable) NSString* title;

@property (nonatomic, strong, nullable) NSOrderedSet<TSLibraryImage*> *images;
- (nullable NSMutableOrderedSet<TSLibraryImage*>*)imagesSet;

@property (nonatomic, strong, nullable) TSLibraryAlbumCollection *parentCollection;

@end

@interface _TSLibraryAlbum (ImagesCoreDataGeneratedAccessors)
- (void)addImages:(NSOrderedSet<TSLibraryImage*>*)value_;
- (void)removeImages:(NSOrderedSet<TSLibraryImage*>*)value_;
- (void)addImagesObject:(TSLibraryImage*)value_;
- (void)removeImagesObject:(TSLibraryImage*)value_;

- (void)insertObject:(TSLibraryImage*)value inImagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromImagesAtIndex:(NSUInteger)idx;
- (void)insertImages:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeImagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInImagesAtIndex:(NSUInteger)idx withObject:(TSLibraryImage*)value;
- (void)replaceImagesAtIndexes:(NSIndexSet *)indexes withImages:(NSArray *)values;

@end

@interface _TSLibraryAlbum (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveCreated;
- (void)setPrimitiveCreated:(NSDate*)value;

- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

- (NSMutableOrderedSet<TSLibraryImage*>*)primitiveImages;
- (void)setPrimitiveImages:(NSMutableOrderedSet<TSLibraryImage*>*)value;

- (TSLibraryAlbumCollection*)primitiveParentCollection;
- (void)setPrimitiveParentCollection:(TSLibraryAlbumCollection*)value;

@end

@interface TSLibraryAlbumAttributes: NSObject 
+ (NSString *)created;
+ (NSString *)summary;
+ (NSString *)title;
@end

@interface TSLibraryAlbumRelationships: NSObject
+ (NSString *)images;
+ (NSString *)parentCollection;
@end

NS_ASSUME_NONNULL_END
