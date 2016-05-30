//
//  TSLibraryImageAdjustmentsProxy.m
//  Avocado
//
//  Created by Tristan Seifert on 20160521.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryImageAdjustmentsProxy.h"

#import "TSHumanModels.h"
#import "TSCoreDataStore.h"

@implementation TSLibraryImageAdjustmentsProxy

/**
 * When attempting KVC for an unknown key, check whether the key starts with
 * `tsAdjustment` If so, attempt to fetch a TSLibraryImageAdjustment with
 * that as its property, and the specified image as its parent.
 */
- (id) valueForUndefinedKey:(NSString *) key {
	TSLibraryImageAdjustment *adj;
	NSPredicate *imPred, *keyPred, *predicate;
	
	// set up a search predicate with which to search for the image
	imPred = [NSPredicate predicateWithFormat:@"image == %@", self.image];
	keyPred = [NSPredicate predicateWithFormat:@"property == %@", key];
	
	predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[imPred, keyPred]];
	
	// ensure key starts with that string
	if([key rangeOfString:@"tsAdjustment"].length > 0) {
		// if it does, try to find the adjustment
		adj = [TSLibraryImageAdjustment TSFindFirstWithPredicate:predicate
														sortedBy:@"dateAdded" ascending:NO
													   inContext:self.image.managedObjectContext];
		
		if(adj != nil) {
			return adj;
		}
		
		// the adjustment couldn't be found; this means certain doom
		DDLogWarn(@"Couldn't find adjustment %@ on %@; falling back to default behaviour for undefined key", key, self.image);
	}
	
	// if we couldn't find the key, use the default behaviour
	return [super valueForUndefinedKey:key];
}

@end
