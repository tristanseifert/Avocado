//
//  TSLibraryOverviewLightTableController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//


#import "TSLibraryOverviewLightTableController.h"

#import "TSLibraryLightTableCell.h"

@interface TSLibraryOverviewLightTableController ()

@property (nonatomic) IKImageBrowserView *gridView;

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
	}
	
	return self;
}


#pragma mark Data Source
/**
 * Returns the number of images that are in the image browser.
 */
- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser {
	return 28;
}

/**
 * Returns an item for the given index.
 */
- (id /*IKImageBrowserItem*/) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index {
	
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

@end
