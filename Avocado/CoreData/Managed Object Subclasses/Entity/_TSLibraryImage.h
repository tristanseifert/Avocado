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

@class TSLibraryAlbum;
@class TSLibraryImageAdjustment;
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

@property (nonatomic, strong, nullable) NSData* pvtAdjustmentData;

@property (nonatomic, strong, nullable) NSString* pvtImageSize;

@property (nonatomic, strong, nullable) NSString* thumbUUID;

@property (nonatomic, strong, nullable) NSString* uuid;

@property (nonatomic, strong, nullable) NSSet<TSLibraryAlbum*> *parentAlbums;
- (nullable NSMutableSet<TSLibraryAlbum*>*)parentAlbumsSet;

@property (nonatomic, strong, nullable) NSSet<TSLibraryImageAdjustment*> *pvtAdjustments;
- (nullable NSMutableSet<TSLibraryImageAdjustment*>*)pvtAdjustmentsSet;

@property (nonatomic, strong, nullable) NSSet<TSLibraryTag*> *tags;
- (nullable NSMutableSet<TSLibraryTag*>*)tagsSet;

@end

@interface _TSLibraryImage (ParentAlbumsCoreDataGeneratedAccessors)
- (void)addParentAlbums:(NSSet<TSLibraryAlbum*>*)value_;
- (void)removeParentAlbums:(NSSet<TSLibraryAlbum*>*)value_;
- (void)addParentAlbumsObject:(TSLibraryAlbum*)value_;
- (void)removeParentAlbumsObject:(TSLibraryAlbum*)value_;

@end

@interface _TSLibraryImage (PvtAdjustmentsCoreDataGeneratedAccessors)
- (void)addPvtAdjustments:(NSSet<TSLibraryImageAdjustment*>*)value_;
- (void)removePvtAdjustments:(NSSet<TSLibraryImageAdjustment*>*)value_;
- (void)addPvtAdjustmentsObject:(TSLibraryImageAdjustment*)value_;
- (void)removePvtAdjustmentsObject:(TSLibraryImageAdjustment*)value_;

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

- (NSData*)primitivePvtAdjustmentData;
- (void)setPrimitivePvtAdjustmentData:(NSData*)value;

- (NSString*)primitivePvtImageSize;
- (void)setPrimitivePvtImageSize:(NSString*)value;

- (NSString*)primitiveThumbUUID;
- (void)setPrimitiveThumbUUID:(NSString*)value;

- (NSString*)primitiveUuid;
- (void)setPrimitiveUuid:(NSString*)value;

- (NSMutableSet<TSLibraryAlbum*>*)primitiveParentAlbums;
- (void)setPrimitiveParentAlbums:(NSMutableSet<TSLibraryAlbum*>*)value;

- (NSMutableSet<TSLibraryImageAdjustment*>*)primitivePvtAdjustments;
- (void)setPrimitivePvtAdjustments:(NSMutableSet<TSLibraryImageAdjustment*>*)value;

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
+ (NSString *)pvtAdjustmentData;
+ (NSString *)pvtImageSize;
+ (NSString *)thumbUUID;
+ (NSString *)uuid;
@end

@interface TSLibraryImageRelationships: NSObject
+ (NSString *)parentAlbums;
+ (NSString *)pvtAdjustments;
+ (NSString *)tags;
@end

NS_ASSUME_NONNULL_END
