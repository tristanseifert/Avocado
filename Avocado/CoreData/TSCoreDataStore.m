//
//  TSCoreDataStore.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreDataStore.h"

#import <MagicalRecord/MagicalRecord.h>


@implementation TSCoreDataStore

/**
 * Initializes the store.
 */
- (instancetype) init {
	if(self = [super init]) {
		// set up, pls
		[MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreAtURL:self.storeUrl];
	}
	
	return self;
}

/**
 * Cleans up the store, before the app quits.
 */
- (void) cleanUp {
	[MagicalRecord cleanUp];
}

#pragma mark Properties
/**
 * Returns the url of the store, in the Application Support directory.
 */
- (NSURL *) storeUrl {
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSError *err = nil;
	
	// get the directory pls
	NSURL *appSupportURL = [[fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	appSupportURL = [appSupportURL URLByAppendingPathComponent:@"me.tseifert.Avocado"];
	
	// create directory, if needed
	[fm createDirectoryAtURL:appSupportURL withIntermediateDirectories:YES
				  attributes:nil error:&err];
	
	if(err != nil) {
		DDLogError(@"Could not create Application Support directory: %@", appSupportURL);
		DDLogError(@"This is a CRITICAL error. The application cannot continue and will exit.");
		
		[NSApp presentError:err];
		exit(-1);
	}
	
	// get the url for the store
	return [appSupportURL URLByAppendingPathComponent:@"Library.avocadocatalog" isDirectory:NO];
}

@end
