//
//  NSManagedObjectContext+TSCoreDataStore.m
//  Avocado
//
//  Created by Tristan Seifert on 20160530.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "NSManagedObjectContext+TSCoreDataStore.h"

@implementation NSManagedObjectContext (TSCoreDataStore)

/**
 * Saves this context, taking into account the specified options. When the save
 * is completed, the callback is run.
 */
- (void) TSSaveWithOptions:(TSSaveOptions) options andCallback:(TSCoreDataStoreSaveCallback) callback {
	__block BOOL hasChanges = NO;
	
	// Determine if the context has changes.
	[self performBlockAndWait:^{
		hasChanges = self.hasChanges;
	}];
	
	if(!hasChanges) {
		// If there are no changes to save, return.
		DDLogInfo(@"Not saving %@; no changes", self);
		
		if(callback) {
			callback(NO, nil);
		}
		return;
	}
	
	// Check some options
	BOOL saveParentContexts = ((options & kTSSaveParentContexts) == kTSSaveParentContexts);
	BOOL saveSynchronously = ((options & kTSSaveContextSynchronously) == kTSSaveContextSynchronously);
	
	// TODO: Figure out whether synchronous saving could deadlock
	
	// Set up a block for saving; this makes the synchronicity easier.
	void (^saveBlock)() = ^{
		NSError *err = nil;
		BOOL saved = NO;
		
		// Save the receiver first.
		saved = [self save:&err];
		
		if(err != nil) {
			DDLogError(@"Error saving %@: %@", self, err);
		}
		
		// If the parent context is to be saved, call its save method.
		NSManagedObjectContext *parent = self.parentContext;
		
		if(saved && saveParentContexts && parent != nil) {
			/*
			 * Modify the user-specified options bitfield. If something above
			 * determines that saving synchronously may cause a deadlock, the
			 * "save synchronously" bit must be removed from the options when
			 * calling the parent context's save method.
			 */
			TSSaveOptions parentOptions = options;
			
			if (saveSynchronously) {
				parentOptions |= kTSSaveContextSynchronously;
			} else {
				parentOptions &= ~kTSSaveContextSynchronously;
			}
			
			[parent TSSaveWithOptions:parentOptions andCallback:callback];
		}
		// Do not save the parent; just execute the callback.
		else {
			if(saved) {
				DDLogVerbose(@"Finished saving %@", self);
			}
			
			// Execute callback
			if(callback) {
				callback(saved, err);
			}
		}
	};
	
	// Depending on the synchronicity flag, perform the save.
	if(saveSynchronously) {
		[self performBlockAndWait:saveBlock];
	} else {
		[self performBlock:saveBlock];
	}
}

@end
