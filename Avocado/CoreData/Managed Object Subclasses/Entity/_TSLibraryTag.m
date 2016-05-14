// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryTag.m instead.

#import "_TSLibraryTag.h"

@implementation TSLibraryTagID
@end

@implementation _TSLibraryTag

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Tag";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:moc_];
}

- (TSLibraryTagID*)objectID {
	return (TSLibraryTagID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic title;

@dynamic images;

- (NSMutableSet<TSLibraryImage*>*)imagesSet {
	[self willAccessValueForKey:@"images"];

	NSMutableSet<TSLibraryImage*> *result = (NSMutableSet<TSLibraryImage*>*)[self mutableSetValueForKey:@"images"];

	[self didAccessValueForKey:@"images"];
	return result;
}

@end

@implementation TSLibraryTagAttributes 
+ (NSString *)title {
	return @"title";
}
@end

@implementation TSLibraryTagRelationships 
+ (NSString *)images {
	return @"images";
}
@end

