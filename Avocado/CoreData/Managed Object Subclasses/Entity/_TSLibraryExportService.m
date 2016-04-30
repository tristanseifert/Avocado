// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TSLibraryExportService.m instead.

#import "_TSLibraryExportService.h"

const struct TSLibraryExportServiceAttributes TSLibraryExportServiceAttributes = {
	.instanceUuid = @"instanceUuid",
	.plugin = @"plugin",
	.settings = @"settings",
	.title = @"title",
};

@implementation TSLibraryExportServiceID
@end

@implementation _TSLibraryExportService

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ExportService" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ExportService";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ExportService" inManagedObjectContext:moc_];
}

- (TSLibraryExportServiceID*)objectID {
	return (TSLibraryExportServiceID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic instanceUuid;

@dynamic plugin;

@dynamic settings;

@dynamic title;

@end

