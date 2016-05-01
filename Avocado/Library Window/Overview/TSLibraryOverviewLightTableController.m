//
//  TSLibraryOverviewLightTableController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <MagicalRecord/MagicalRecord.h>

#import "TSLibraryOverviewLightTableController.h"
#import "TSImportController.h"
#import "TSLibraryLightTableCell.h"
#import "TSHumanModels.h"

@interface TSLibraryOverviewLightTableController ()

@property (nonatomic) NSArray<TSLibraryImage *> *imagesToShow;
@property (nonatomic) IKImageBrowserView *gridView;

- (void) refetchImages;
- (void) imageDidImportNotification:(NSNotification *) n;

@end

@implementation TSLibraryOverviewLightTableController

/**
 * Initialises the controller.
 */
- (instancetype) initWithGridView:(IKImageBrowserView *) view {
	if(self = [super init]) {
		self.gridView = view;
		
		// we're both its delegate and its data source
		self.gridView.dataSource = self;
		self.gridView.delegate = self;
		
		self.gridView.zoomValue = 0.5;
		
		self.gridView.intercellSpacing = NSZeroSize;
		
		// notificationmaru!~!!!!1~~~
		NSNotificationCenter *tomato = [NSNotificationCenter defaultCenter];
		[tomato addObserver:self
				   selector:@selector(imageDidImportNotification:)
					   name:TSFileImportedNotificationName object:nil];
	}
	
	return self;
}

/**
 * cleans up some shit
 */
- (void) dealloc {
	// remove notification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Data Source
/**
 * Returns the number of images that are in the image browser.
 */
- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser {
	return self.imagesToShow.count;
}

/**
 * Returns an item for the given index.
 */
- (id /*IKImageBrowserItem*/) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger) index {
	return self.imagesToShow[index];
}

/**
 * The images at the given index set should be moved to the destination index.
 *
 * @note drag re-ordering is ignored, unless a single collection is currently
 * selected.
 */
- (BOOL) imageBrowser:(IKImageBrowserView *) aBrowser
   moveItemsAtIndexes: (NSIndexSet *) indexes
			  toIndex:(NSUInteger) destinationIndex {
	return NO;
}

#pragma mark Delegate
/**
 * An image cell has been right-clicked.
 */
- (void) imageBrowser:(IKImageBrowserView *) aBrowser cellWasRightClickedAtIndex:(NSUInteger) index
			withEvent:(NSEvent *) event {
	
}

/**
 * A cell was double-clicked; go to the edit view.
 */
- (void) imageBrowser:(IKImageBrowserView *) aBrowser cellWasDoubleClickedAtIndex:(NSUInteger) index {
	
}

#pragma mark Fetch Request Handling
/**
 * Sets the fetch request, executes it, and updates the grid view.
 */
- (void) setFetchRequest:(NSFetchRequest *) fetchRequest {
	// set it first, pls
	_fetchRequest = [fetchRequest copy];
	
	// set the properties to fetch
	self.fetchRequest.fetchBatchSize = 30;
	
	self.fetchRequest.includesPropertyValues =  YES;
	self.fetchRequest.shouldRefreshRefetchedObjects = YES;
	
	// EGGsecute it
	[self refetchImages];
}

/**
 * Executes the fetch request, then updates the image view
 */
- (void) refetchImages {
	self.imagesToShow = [TSLibraryImage MR_executeFetchRequest:self.fetchRequest];
	
	[self.gridView reloadData];
}

/**
 * Notification fired when an image importing thing completes. This does the
 * Shitty Thing™ and just re-evaluates the fetch request because we're really
 * fucking lazy.
 */
- (void) imageDidImportNotification:(NSNotification *) n {
	dispatch_async(dispatch_get_main_queue(), ^{
		DDLogVerbose(@"did the import thing: %@", n);
		
		[self refetchImages];
	});
}

@end
