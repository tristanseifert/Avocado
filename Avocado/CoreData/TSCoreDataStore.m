//
//  TSCoreDataStore.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreDataStore.h"
#import "TSGroupContainerHelper.h"

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
	// get the directory and append filename
	NSURL *appSupportURL = [TSGroupContainerHelper sharedInstance].appSupport;
	return [appSupportURL URLByAppendingPathComponent:@"Library.avocadocatalog"
										  isDirectory:NO];
}

@end
