//
//  TSCoreDataStoreIB.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreDataStoreIB.h"

#import <MagicalRecord/MagicalRecord.h>

@interface TSCoreDataStoreIB ()

- (void) createContext;

@property (nonatomic, readwrite) NSManagedObjectContext *moc;

@end

@implementation TSCoreDataStoreIB

/**
 * Desginated initializer.
 */
- (instancetype) init {
	if(self = [super init]) {
		[self createContext];
	}
	
	return self;
}

/**
 * Run the same method, but when run from a nib.
 */
- (void) awakeFromNib {
	[super awakeFromNib];
	
	[self createContext];
}

/**
 * Creates the context.
 */
- (void) createContext {
	self.moc = [NSManagedObjectContext MR_newMainQueueContext];
}

@end
