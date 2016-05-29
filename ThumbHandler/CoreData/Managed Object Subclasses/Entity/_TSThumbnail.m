// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSThumbnail.m instead.

#import "_TSThumbnail.h"

@implementation TSThumbnailID
@end

@implementation _TSThumbnail

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Thumbnail" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Thumbnail";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Thumbnail" inManagedObjectContext:moc_];
}

- (TSThumbnailID*)objectID {
	return (TSThumbnailID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic dateAdded;

@dynamic dateLastAccessed;

@dynamic directory;

@dynamic filename;

@dynamic imageUuid;

@end

@implementation TSThumbnailAttributes 
+ (NSString *)dateAdded {
	return @"dateAdded";
}
+ (NSString *)dateLastAccessed {
	return @"dateLastAccessed";
}
+ (NSString *)directory {
	return @"directory";
}
+ (NSString *)filename {
	return @"filename";
}
+ (NSString *)imageUuid {
	return @"imageUuid";
}
@end

