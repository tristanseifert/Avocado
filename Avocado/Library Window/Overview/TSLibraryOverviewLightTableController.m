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

- (void) scrollViewSizeChanged:(NSNotification *) n;

@end

@implementation TSLibraryOverviewLightTableController

/**
 * Initialises the controller.
 */
- (instancetype) initWithGridView:(IKImageBrowserView *) view {
	if(self = [super init]) {
		self.gridView = view;
		
		self.cellsPerRow = 2;
		
		// we're both its delegate and its data source
		self.gridView.dataSource = self;
		self.gridView.delegate = self;
		
		// set cell layout and resizing behaviour
		self.gridView.intercellSpacing = NSZeroSize;
		
		[self.gridView setContentResizingMask:NSViewWidthSizable];
		
		// notificationmaru!~!!!!1~~~
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center addObserver:self
				   selector:@selector(imageDidImportNotification:)
					   name:TSFileImportedNotificationName object:nil];
		
		// observe size changes to the enclosing scroll view
		NSScrollView *scroll = self.gridView.enclosingScrollView;
		scroll.postsFrameChangedNotifications = YES;
		
		[center addObserver:self
				   selector:@selector(scrollViewSizeChanged:)
					   name:NSViewFrameDidChangeNotification
					 object:scroll];
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

#pragma mark Resizing
/**
 * resizes the cells.
 */
- (void) resizeCells {
	CGFloat cellWidth = floorf(self.gridView.frame.size.width / ((CGFloat) self.cellsPerRow));
	CGFloat cellHeight = cellWidth * 0.74;
	
	[self.gridView setCellSize:NSMakeSize(cellWidth, cellHeight)];
}

/**
 * The frame of the scroll view containing the grid changed, so update the cell
 * size.
 */
- (void) scrollViewSizeChanged:(NSNotification *) n {
	DDLogVerbose(@"Size of scroll view changed: %@", NSStringFromRect(self.gridView.enclosingScrollView.frame));
	
	[self resizeCells];
}

@end
