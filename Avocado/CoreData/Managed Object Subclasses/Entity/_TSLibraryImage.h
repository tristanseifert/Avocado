// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImage.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class TSLibraryImageAdjustment;
@class TSLibraryAlbum;
@class TSLibraryTag;

@class NSObject;

@class NSObject;

@interface TSLibraryImageID : NSManagedObjectID {}
@end

@interface _TSLibraryImage : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TSLibraryImageID *objectID;

@property (nonatomic, strong, nullable) NSDate* dateImported;

@property (nonatomic, strong, nullable) NSDate* dateModified;

@property (nonatomic, strong, nullable) NSDate* dateShot;

@property (nonatomic, strong, nullable) NSNumber* dayShot;

@property (atomic) double dayShotValue;
- (double)dayShotValue;
- (void)setDayShotValue:(double)value_;

@property (nonatomic, strong, nullable) NSNumber* fileType;

@property (atomic) int16_t fileTypeValue;
- (int16_t)fileTypeValue;
- (void)setFileTypeValue:(int16_t)value_;

@property (nonatomic, strong, nullable) id fileUrl;

@property (nonatomic, strong, nullable) id metadata;

@property (nonatomic, strong, nullable) NSString* pvtImageSize;

@property (nonatomic, strong, nullable) NSString* thumbUUID;

@property (nonatomic, strong, nullable) NSString* uuid;

@property (nonatomic, strong, nullable) NSOrderedSet<TSLibraryImageAdjustment*> *adjustments;
- (nullable NSMutableOrderedSet<TSLibraryImageAdjustment*>*)adjustmentsSet;

@property (nonatomic, strong, nullable) NSSet<TSLibraryAlbum*> *parentAlbums;
- (nullable NSMutableSet<TSLibraryAlbum*>*)parentAlbumsSet;

@property (nonatomic, strong, nullable) NSSet<TSLibraryTag*> *tags;
- (nullable NSMutableSet<TSLibraryTag*>*)tagsSet;

@end

@interface _TSLibraryImage (AdjustmentsCoreDataGeneratedAccessors)
- (void)addAdjustments:(NSOrderedSet<TSLibraryImageAdjustment*>*)value_;
- (void)removeAdjustments:(NSOrderedSet<TSLibraryImageAdjustment*>*)value_;
- (void)addAdjustmentsObject:(TSLibraryImageAdjustment*)value_;
- (void)removeAdjustmentsObject:(TSLibraryImageAdjustment*)value_;

- (void)insertObject:(TSLibraryImageAdjustment*)value inAdjustmentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAdjustmentsAtIndex:(NSUInteger)idx;
- (void)insertAdjustments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAdjustmentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAdjustmentsAtIndex:(NSUInteger)idx withObject:(TSLibraryImageAdjustment*)value;
- (void)replaceAdjustmentsAtIndexes:(NSIndexSet *)indexes withAdjustments:(NSArray *)values;

@end

@interface _TSLibraryImage (ParentAlbumsCoreDataGeneratedAccessors)
- (void)addParentAlbums:(NSSet<TSLibraryAlbum*>*)value_;
- (void)removeParentAlbums:(NSSet<TSLibraryAlbum*>*)value_;
- (void)addParentAlbumsObject:(TSLibraryAlbum*)value_;
- (void)removeParentAlbumsObject:(TSLibraryAlbum*)value_;

@end

@interface _TSLibraryImage (TagsCoreDataGeneratedAccessors)
- (void)addTags:(NSSet<TSLibraryTag*>*)value_;
- (void)removeTags:(NSSet<TSLibraryTag*>*)value_;
- (void)addTagsObject:(TSLibraryTag*)value_;
- (void)removeTagsObject:(TSLibraryTag*)value_;

@end

@interface _TSLibraryImage (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveDateImported;
- (void)setPrimitiveDateImported:(NSDate*)value;

- (NSDate*)primitiveDateModified;
- (void)setPrimitiveDateModified:(NSDate*)value;

- (NSDate*)primitiveDateShot;
- (void)setPrimitiveDateShot:(NSDate*)value;

- (NSNumber*)primitiveDayShot;
- (void)setPrimitiveDayShot:(NSNumber*)value;

- (double)primitiveDayShotValue;
- (void)setPrimitiveDayShotValue:(double)value_;

- (NSNumber*)primitiveFileType;
- (void)setPrimitiveFileType:(NSNumber*)value;

- (int16_t)primitiveFileTypeValue;
- (void)setPrimitiveFileTypeValue:(int16_t)value_;

- (id)primitiveFileUrl;
- (void)setPrimitiveFileUrl:(id)value;

- (id)primitiveMetadata;
- (void)setPrimitiveMetadata:(id)value;

- (NSString*)primitivePvtImageSize;
- (void)setPrimitivePvtImageSize:(NSString*)value;

- (NSString*)primitiveThumbUUID;
- (void)setPrimitiveThumbUUID:(NSString*)value;

- (NSString*)primitiveUuid;
- (void)setPrimitiveUuid:(NSString*)value;

- (NSMutableOrderedSet<TSLibraryImageAdjustment*>*)primitiveAdjustments;
- (void)setPrimitiveAdjustments:(NSMutableOrderedSet<TSLibraryImageAdjustment*>*)value;

- (NSMutableSet<TSLibraryAlbum*>*)primitiveParentAlbums;
- (void)setPrimitiveParentAlbums:(NSMutableSet<TSLibraryAlbum*>*)value;

- (NSMutableSet<TSLibraryTag*>*)primitiveTags;
- (void)setPrimitiveTags:(NSMutableSet<TSLibraryTag*>*)value;

@end

@interface TSLibraryImageAttributes: NSObject 
+ (NSString *)dateImported;
+ (NSString *)dateModified;
+ (NSString *)dateShot;
+ (NSString *)dayShot;
+ (NSString *)fileType;
+ (NSString *)fileUrl;
+ (NSString *)metadata;
+ (NSString *)pvtImageSize;
+ (NSString *)thumbUUID;
+ (NSString *)uuid;
@end

@interface TSLibraryImageRelationships: NSObject
+ (NSString *)adjustments;
+ (NSString *)parentAlbums;
+ (NSString *)tags;
@end

NS_ASSUME_NONNULL_END
