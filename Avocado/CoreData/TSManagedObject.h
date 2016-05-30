//
//  TSManagedObject.h
//  Avocado
//
//  Created by Tristan Seifert on 20160530.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface TSManagedObject : NSManagedObject

/**
 * Creates an entity of this class on the given context.
 */
+ (__kindof TSManagedObject *) TSCreateEntityInContext:(NSManagedObjectContext *) ctx;

/**
 * Returns an instance of the receiver, but on the specified context.
 *
 * This is useful if a user-supplied managed object needs to be used on an
 * internal context.
 */
- (__kindof TSManagedObject *) TSInContext:(NSManagedObjectContext *) ctx;


/**
 * Finds the first instance of this class, using the specified predicate as a
 * search term. The given property is used to sort the array before fetching the
 * first entry.
 */
+ (instancetype) TSFindFirstWithPredicate:(NSPredicate *) searchterm sortedBy:(NSString *) property ascending:(BOOL) ascending inContext:(NSManagedObjectContext *) ctx;


/**
 * Returns a fetch request that will find all instances of this object in the
 * given context.
 */
+ (NSFetchRequest *) TSCreateFetchRequestInContext:(NSManagedObjectContext *) ctx;

/**
 * Creates a fetch request wherein all instances of this class are found that
 * meet the criteria outlined by the given predicate. The results are sorted in
 * either ascending or descending order by sortTerm.
 */
+ (NSFetchRequest *) TSRequestAllSortedBy:(NSString *) sortTerm ascending:(BOOL) ascending withPredicate:(NSPredicate *) searchTerm inContext:(NSManagedObjectContext *) context;


/**
 * Executes the specified fetch request.
 */
+ (NSArray *) TSExecuteFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *) ctx;

/**
 * Executes the specified fetch request, returning only the first object.
 */
+ (__kindof TSManagedObject *) TSExecuteFetchRequestAndReturnFirstObject:(NSFetchRequest *) request inContext:(NSManagedObjectContext *) ctx;

@end
