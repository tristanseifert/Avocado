//
//  TSCoreDataStore.h
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "TSManagedObject.h"

/// Block for which all operations shall take place on the given context
typedef void (^TSCoreDataStoreSaveBlock)(NSManagedObjectContext * _Nonnull);
/// Saving callback block
typedef void (^TSCoreDataStoreSaveCallback)(BOOL, NSError * _Nullable);


/**
 * This class encapsulates the central CoreData store of the application, and
 * should be accessed via the singleton pattern.
 *
 * For maximum performance, the stack creates various default contexts. The
 * main context (which in turn is the child of the persistent store) runs on a
 * background queue, so all disk IO happens on a separate thread.
 *
 * The main thread context, in turn, is the child of this persistence context.
 * By default, all temporary worker contexts will be children of the main thread
 * context, so that the main thread always has up-to-date data.
 */
@interface TSCoreDataStore : NSObject

/// URL to the on-disk sqlite store
@property (nonatomic, readonly, nonnull) NSURL *storeUrl;

/// Main thread managed object context, scheduled on main thread
@property (nonatomic, readonly, nonnull) NSManagedObjectContext *mainThreadMoc;

/**
 * Returns the shared CoreData store, creating a new one if needed.
 */
+ (_Nonnull instancetype) sharedInstance;

/**
 * Cleans up the store, and de-allocates the entire CoreData stack.
 */
- (void) cleanUp;


/**
 * Creates a temporary managed object context, confined to a private queue, with
 * the root context as its parent.
 */
+ (nonnull NSManagedObjectContext *) temporaryWorkerContextWithName:(nonnull NSString *) name;

/**
 * Creates a new worker context, then executes the specified block on it. When
 * the block has finished executing, it is saved, and the optional completion
 * block is run.
 *
 * @note The operations take place asynchronously; this method returns after the
 * operations have been submitted to the temporary context.
 */
+ (void) saveWithBlock:(_Nonnull TSCoreDataStoreSaveBlock) saveBlock completion:(_Nullable TSCoreDataStoreSaveCallback) completion;

/**
 * Creates a new worker context, then executes the specified block on it. When
 * the block has finished executing, it is saved, and the optional completion
 * block is run.
 *
 * @note The operations take place synchronously.
 */
+ (void) saveWithBlockAndWait:(_Nonnull TSCoreDataStoreSaveBlock) saveBlock completion:(_Nullable TSCoreDataStoreSaveCallback) completion;

/**
 * Finds a managed object, given an URL representation of its ID.
 *
 * @param url URL representation of an `NSManagedObjectID` object.
 * @param context Context on which the object shall be looked for. If nil, the
 * main thread context is used.
 */
+ (nullable __kindof TSManagedObject *) findManagedObjectWithUrl:(nonnull NSURL *) url inContext:(nullable NSManagedObjectContext *) context;

@end
