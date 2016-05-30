//
//  TSThumbXPCServiceDelegate.m
//  Avocado
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "TSThumbXPCServiceDelegate.h"
#import "TSThumbHandler.h"
#import "TSGroupContainerHelper.h"

@interface TSThumbXPCServiceDelegate ()

/// Managed object model
@property (nonatomic) NSManagedObjectModel *model;
/// Root managed object context; connected to the store coordinator for the thumb store.
@property (nonatomic) NSManagedObjectContext *moc;

@end

@implementation TSThumbXPCServiceDelegate

/**
 * On initialization, set up the CoreData store as well.
 */
- (instancetype) init {
	if(self = [super init]) {
		NSError *err = nil;
		
		// Get the url for the store
		NSURL *cachesUrl = [TSGroupContainerHelper sharedInstance].caches;
		cachesUrl = [cachesUrl URLByAppendingPathComponent:@"TSThumbCache" isDirectory:YES];
		NSURL *storeUrl = [cachesUrl URLByAppendingPathComponent:@"ThumbCache.sqlite"
													 isDirectory:NO];
		
		// Read the model from file
		NSURL *modelUrl = [[NSBundle mainBundle] URLForResource:@"TSThumbCache" withExtension:@"momd"];
		self.model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelUrl];
		
		// Set up a root parent context
		self.moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		self.moc.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
		self.moc.undoManager = nil;
		
		// Add the on-disk store
		NSDictionary *options = @{
			// Automagically migrate the persistent store
			NSMigratePersistentStoresAutomaticallyOption: @YES,
			// Ise lightweight migration to infer the model
			NSInferMappingModelAutomaticallyOption: @YES
		};
		
		[self.moc.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														  configuration:nil URL:storeUrl options:options error:&err];
	}
	
	return self;
}

/**
 * When deallocating, attempt to save the managed object context.
 */
- (void) dealloc {
	// Save the managed object context, ignoring any errors that may appear.
	[self.moc save:nil];
}

/**
 * Determine whether the connection should be accepted, and if so, sets up the
 * connection and resumes it.
 */
- (BOOL) listener:(NSXPCListener *) listener shouldAcceptNewConnection:(NSXPCConnection *) connection {
	// create the interface and object that's exported
	connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(TSThumbHandlerProtocol)];
	connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(TSThumbHandlerDelegate)];
	
	TSThumbHandler *exportedObject = [[TSThumbHandler alloc] initWithRemote:connection.remoteObjectProxy andContext:self.moc];
	connection.exportedObject = exportedObject;
	
	// resume connection to allow it to work
	[connection resume];
	return YES;
}

@end
