// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryImage.m instead.

#import "_TSLibraryImage.h"

const struct TSLibraryImageAttributes TSLibraryImageAttributes = {
	.fileUrl = @"fileUrl",
	.thumbData = @"thumbData",
};

@implementation TSLibraryImageID
@end

@implementation _TSLibraryImage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Image";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Image" inManagedObjectContext:moc_];
}

- (TSLibraryImageID*)objectID {
	return (TSLibraryImageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic fileUrl;

@dynamic thumbData;

@end

