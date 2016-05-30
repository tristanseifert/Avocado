//
//  TSCoreDataStore.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreDataStore.h"
#import "TSGroupContainerHelper.h"

#import "NSManagedObjectContext+TSCoreDataStore.h"

#import <CoreData/CoreData.h>

/// Shared instance of the CoreData store
static TSCoreDataStore *sharedInstance = nil;


@interface TSCoreDataStore ()

/// Schema to use for the CoreData context
@property (nonatomic) NSManagedObjectModel *storeSchema;

/// Persistent store coordinator for root context
@property (nonatomic) NSPersistentStoreCoordinator *rootPsc;
/// On-disk sqlite persistent store
@property (nonatomic) NSPersistentStore *rootStore;

/// Root managed object context; connected to persistent store, uses private queue
@property (nonatomic) NSManagedObjectContext *rootMoc;
/// Main thread managed object context, scheduled on main thread
@property (nonatomic) NSManagedObjectContext *mainThreadMoc;

- (void) initRootContext;
- (void) initMainThreadContext;

- (NSManagedObjectContext *) _temporaryWorkerContextWithName:(NSString *) name;
- (__kindof TSManagedObject *) _findManagedObjectWithUrl:(NSURL *) url inContext:(NSManagedObjectContext *) context;

@end

@implementation TSCoreDataStore

/**
 * Returns the shared CoreData store, creating a new one if needed.
 */
+ (instancetype) sharedInstance {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self class] new];
	});
	
	return sharedInstance;
}

#pragma mark Setup
/**
 * Initializes the store.
 */
- (instancetype) init {
	if(self = [super init]) {
		[self initRootContext];
		[self initMainThreadContext];
	}
	
	return self;
}

/**
 * Initializes the root context, including its model and persistent store.
 */
- (void) initRootContext {
	NSError *err = nil;
	
	// Read the schema from file
	NSURL *modelUrl = [[NSBundle mainBundle] URLForResource:@"Avocado" withExtension:@"momd"];
	self.storeSchema = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelUrl];
	
	// Set up a root parent context
	self.rootMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	self.rootPsc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.storeSchema];
	
	self.rootMoc.persistentStoreCoordinator = self.rootPsc;
	
	// Add the on-disk store
	NSDictionary *options = @{
		// Automagically migrate the persistent store
		NSMigratePersistentStoresAutomaticallyOption: @YES,
		// Use lightweight migration to infer the model mapping
		NSInferMappingModelAutomaticallyOption: @YES
	};
	
	self.rootStore = [self.rootPsc addPersistentStoreWithType:NSSQLiteStoreType
												configuration:nil URL:self.storeUrl
													  options:options error:&err];
	
	// Check for errors
	if(err != nil) {
		DDLogError(@"Error adding persistent store: %@", err);
		
		// TODO: Do something more graceful than crash
		[NSApp presentError:err];
		abort();
	}
}

/**
 * Creates a main thread-bound context, using the root context as its parent.
 */
- (void) initMainThreadContext {
	self.mainThreadMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	[self.mainThreadMoc setParentContext:self.rootMoc];
	
	self.mainThreadMoc.name = @"Main Thread Context";
}

/**
 * Cleans up the store, before the app quits.
 */
- (void) cleanUp {
	// Save main thread MOC
	[self.mainThreadMoc performBlockAndWait:^{
		NSError *err = nil;
		
		if([self.mainThreadMoc save:&err] == NO) {
			DDLogError(@"Error saving main thread context: %@", err);
		}
	}];
	
	// Save root context (this saves data to disk)
	[self.rootMoc performBlockAndWait:^{
		NSError *err = nil;
		
		if([self.rootMoc save:&err] == NO) {
			DDLogError(@"Error saving root context: %@", err);
		}
	}];
}

#pragma mark Helpers
/**
 * Creates a temporary managed object context, confined to a private queue, with
 * the root context as its parent.
 */
+ (NSManagedObjectContext *) temporaryWorkerContextWithName:(NSString *) name {
	return [[self sharedInstance] _temporaryWorkerContextWithName:name];
}

- (NSManagedObjectContext *) _temporaryWorkerContextWithName:(NSString *) name {
	NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	[ctx setParentContext:self.mainThreadMoc];
	
	ctx.name = name;
	
	return ctx;
}

/**
 * Creates a new worker context, then executes the specified block on it. When
 * the block has finished executing, it is saved, and the optional completion
 * block is run.
 *
 * @note The operations take place asynchronously; this method returns after the
 * operations have been submitted to the temporary context.
 */
+ (void) saveWithBlock:(TSCoreDataStoreSaveBlock) saveBlock completion:(TSCoreDataStoreSaveCallback) completion {
	NSManagedObjectContext *ctx = [[self class] temporaryWorkerContextWithName:@"Unnamed Temporary Context"];
	
	[ctx performBlock:^{
		// Run the user-provided block
		saveBlock(ctx);
		
		// Save the context and execute completion callback
		[ctx TSSaveWithOptions:kTSSaveParentContexts andCallback:completion];
	}];
}

/**
 * Creates a new worker context, then executes the specified block on it. When
 * the block has finished executing, it is saved, and the optional completion
 * block is run.
 *
 * @note The operations take place synchronously.
 */
+ (void) saveWithBlockAndWait:(TSCoreDataStoreSaveBlock) saveBlock completion:(TSCoreDataStoreSaveCallback) completion {
	NSManagedObjectContext *ctx = [[self class] temporaryWorkerContextWithName:@"Unnamed Temporary Context"];
	
	[ctx performBlockAndWait:^{
		// Run the user-provided block
		saveBlock(ctx);
		
		// Save the context and execute completion callback
		[ctx TSSaveWithOptions:kTSSaveParentContexts andCallback:completion];
	}];
}

/**
 * Finds a managed object, given an URL representation of its ID.
 *
 * @param url URL representation of an `NSManagedObjectID` object.
 * @param context Context on which the object shall be looked for. If nil, the
 * main thread context is used.
 */
+ (nullable __kindof TSManagedObject *) findManagedObjectWithUrl:(NSURL *) url inContext:(NSManagedObjectContext *) context {
	return [[self sharedInstance] _findManagedObjectWithUrl:url inContext:context];
}

- (__kindof TSManagedObject *) _findManagedObjectWithUrl:(NSURL *) url inContext:(NSManagedObjectContext *) inContext {
	NSManagedObjectID *objId;
	NSError *err = nil;
	
	// Validate parameters
	DDAssert(url != nil, @"url may not be nil");
	
	// Figure out the context to use
	NSManagedObjectContext *ctx = (inContext == nil) ? self.mainThreadMoc : inContext;
	
	// Try to get an object ID from the persistent store
	objId = [self.rootPsc managedObjectIDForURIRepresentation:url];
	
	if(objId == nil) {
		// If the object ID is nil, the store may be incorrect
		return nil;
	}
	
	// Try to find the object in the given context
	TSManagedObject *obj = [ctx existingObjectWithID:objId error:&err];

	if(err != nil) {
		DDLogError(@"Couldn't find object for id %@: %@", url, err);
		return nil;
	}
	
	return obj;
}

#pragma mark Properties
/**
 * Returns the url of the store, in the Application Support directory.
 */
- (NSURL *) storeUrl {
	// Get the directory and append the store filename
	NSURL *appSupportURL = [TSGroupContainerHelper sharedInstance].appSupport;
	return [appSupportURL URLByAppendingPathComponent:@"Library.avocadocatalog"
										  isDirectory:NO];
}

@end
