//
//  TSManagedObject.m
//  Avocado
//
//  Created by Tristan Seifert on 20160530.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSManagedObject.h"

@interface TSManagedObject ()

+ (NSEntityDescription *) TSEntityDescriptionInContext:(NSManagedObjectContext *) ctx;
+ (NSString *) TSEntityName;

// stub for mogenerator
+ (instancetype) insertInManagedObjectContext:(NSManagedObjectContext *) moc;

@end

@implementation TSManagedObject

/**
 * Creates an entity of this class on the given context.
 */
+ (__kindof TSManagedObject *) TSCreateEntityInContext:(NSManagedObjectContext *) ctx {
	// Check if the generated subclasses support this convenience method
	if([self respondsToSelector:@selector(insertInManagedObjectContext:)] && ctx != nil) {
		id entity = [self performSelector:@selector(insertInManagedObjectContext:) withObject:ctx];
		return entity;
	}
	// If they don't, get the entity description and do it manually
	else {
		NSEntityDescription *entity = nil;
		
		entity  = [self TSEntityDescriptionInContext:ctx];
		
		if (entity == nil) {
			return nil;
		}
		
		return [[self alloc] initWithEntity:entity insertIntoManagedObjectContext:ctx];
	}
}

/**
 * Returns an instance of the receiver, but on the specified context.
 *
 * This is useful if a user-supplied managed object needs to be used on an
 * internal context.
 */
- (__kindof TSManagedObject *) TSInContext:(NSManagedObjectContext *) ctx {
	NSManagedObject *obj;
	NSError *err = nil;
	
	// Get object ID of the receiver
	NSManagedObjectID *theID = self.objectID;
	
	// Fetch this object from the given context
	obj = [ctx existingObjectWithID:theID error:&err];
	
	if(err != nil) {
		DDLogError(@"Couldn't move object %@ to context %@: %@", self, ctx, err);
		return nil;
	}
	
	return (TSManagedObject *) obj;
}

#pragma mark Searching
/**
 * Finds the first instance of this class, using the specified predicate as a
 * search term. The given property is used to sort the array before fetching the
 * first entry.
 */
+ (instancetype) TSFindFirstWithPredicate:(NSPredicate *) searchterm
								 sortedBy:(NSString *) property
								ascending:(BOOL) ascending
								inContext:(NSManagedObjectContext *) ctx {
	NSFetchRequest *request = [self TSRequestAllSortedBy:property ascending:ascending withPredicate:searchterm inContext:ctx];
	
	return [self TSExecuteFetchRequestAndReturnFirstObject:request inContext:ctx];
}

#pragma mark Fetch Request Creation
/**
 * Returns a fetch request that will find all instances of this object in the
 * given context.
 */
+ (NSFetchRequest *) TSCreateFetchRequestInContext:(NSManagedObjectContext *) ctx {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	request.entity = [self TSEntityDescriptionInContext:ctx];
	
	return request;
}

/**
 * Creates a fetch request wherein all instances of this class are found that
 * meet the criteria outlined by the given predicate. The results are sorted in
 * either ascending or descending order by sortTerm.
 */
+ (NSFetchRequest *) TSRequestAllSortedBy:(NSString *) sortTerm ascending:(BOOL) ascending withPredicate:(NSPredicate *) searchTerm inContext:(NSManagedObjectContext *) context {
	NSFetchRequest *request = [self TSCreateFetchRequestInContext:context];
	
	// Set the search term, if specified
	if(searchTerm) {
		request.predicate = searchTerm;
	}
	
	// Support batching
	request.fetchBatchSize = 50;
	
	// Set up search descriptors
	NSMutableArray *sortDescriptors = [NSMutableArray new];
	NSArray *sortKeys = [sortTerm componentsSeparatedByString:@","];
	
	for (__strong NSString *sortKey in sortKeys) {
		NSArray *sortComponents = [sortKey componentsSeparatedByString:@":"];
		
		if (sortComponents.count > 1) {
			NSString *customAscending = sortComponents.lastObject;
			ascending = customAscending.boolValue;
			sortKey = sortComponents[0];
		}
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:ascending];
		[sortDescriptors addObject:sortDescriptor];
	}
	
	request.sortDescriptors = [sortDescriptors copy];
	
	return request;
}

#pragma mark Fetch Request Evaluation
/**
 * Executes the specified fetch request.
 */
+ (NSArray *) TSExecuteFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *) ctx {
	__block NSArray *results = nil;
	
	// Ensure the fetch request is performed on the context's queue
	[ctx performBlockAndWait:^{
		NSError *err = nil;
		
		// Perform request
		results = [ctx executeFetchRequest:request error:&err];
		
		// Handle errors
		if(results == nil || err != nil) {
			DDLogError(@"Couldn't fetch results: %@", err);
		}
		
	}];
	
	return results;
}

/**
 * Executes the specified fetch request, returning only the first object.
 */
+ (__kindof TSManagedObject *) TSExecuteFetchRequestAndReturnFirstObject:(NSFetchRequest *) request inContext:(NSManagedObjectContext *) ctx {
	// Fetch only the first object
	request.fetchLimit = 1;
	
	// Get the results array
	NSArray *results = [self TSExecuteFetchRequest:request inContext:ctx];
	if(results.count == 0) {
		return nil;
	}
	
	// Return the first object
	return [results firstObject];
}


#pragma mark Internal Secrets
/**
 * Creates an entity description for the receiver, on the given managed object
 * context.
 */
+ (NSEntityDescription *) TSEntityDescriptionInContext:(NSManagedObjectContext *) ctx {
	NSString *entityName = [self TSEntityName];
	return [NSEntityDescription entityForName:entityName inManagedObjectContext:ctx];
}

/**
 * Return the entity name of this class. This assumes that the generated object
 * subclasses implement a class method called `entityName` which is the case
 * with mogenerator.
 */
+ (NSString *) TSEntityName {
	return [self performSelector:@selector(entityName)];
}

#pragma mark Stubs
+ (instancetype) insertInManagedObjectContext:(NSManagedObjectContext *) moc {
	return nil;
}

@end
