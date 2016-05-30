//
//  NSManagedObjectContext+TSCoreDataStore.h
//  Avocado
//
//  Created by Tristan Seifert on 20160530.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "TSCoreDataStore.h"

/**
 * Various options to pass to the saving function. Multiple options may be
 * combined by using a bitwise OR.
 */
typedef NS_ENUM(NSUInteger, TSSaveOptions) {
	/**
	 * Save the parent of this context as well. Note that this context itself is
	 * saved first.
	 */
	kTSSaveParentContexts = (1 << 24),
	
	/**
	 * When set, the context is saved synchronously; i.e. the save method will
	 * not return until the save is completed.
	 */
	kTSSaveContextSynchronously = (1 << 25)
};

@interface NSManagedObjectContext (TSCoreDataStore)

/**
 * Saves this context, taking into account the specified options. When the save
 * is completed, the callback is run.
 */
- (void) TSSaveWithOptions:(TSSaveOptions) options andCallback:(nullable TSCoreDataStoreSaveCallback) callback;

@end
