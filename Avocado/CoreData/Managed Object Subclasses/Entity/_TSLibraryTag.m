// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryTag.m instead.

#import "_TSLibraryTag.h"

const struct TSLibraryTagAttributes TSLibraryTagAttributes = {
	.title = @"title",
};

const struct TSLibraryTagRelationships TSLibraryTagRelationships = {
	.images = @"images",
};

@implementation TSLibraryTagID
@end

@implementation _TSLibraryTag

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
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

- (NSMutableSet*)imagesSet {
	[self willAccessValueForKey:@"images"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"images"];

	[self didAccessValueForKey:@"images"];
	return result;
}

@end

