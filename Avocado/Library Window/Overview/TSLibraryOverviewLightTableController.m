//
//  TSLibraryOverviewLightTableController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <CNGridView/CNGridViewItemLayout.h>

#import "TSLibraryOverviewLightTableController.h"

#import "TSLibraryLightTableCell.h"

@interface TSLibraryOverviewLightTableController ()

@property (nonatomic) CNGridView *gridView;

@property (strong) CNGridViewItemLayout *defaultLayout;
@property (strong) CNGridViewItemLayout *hoverLayout;
@property (strong) CNGridViewItemLayout *selectionLayout;

@end

@implementation TSLibraryOverviewLightTableController

/**
 * Initialises the controller.
 */
- (instancetype) initWithGridView:(CNGridView *) view {
	if(self = [super init]) {
		self.gridView = view;
		
		// we're both its delegate and its data source
		self.gridView.dataSource = self;
		self.gridView.delegate = self;
		
		// set up the layouts for default/selection/hover
		self.defaultLayout = [CNGridViewItemLayout defaultLayout];
		self.hoverLayout = [CNGridViewItemLayout defaultLayout];
		self.selectionLayout = [CNGridViewItemLayout defaultLayout];
		
		self.hoverLayout.backgroundColor = [[NSColor grayColor] colorWithAlphaComponent:0.42];
		self.selectionLayout.backgroundColor = [NSColor colorWithCalibratedRed:0.542 green:0.699 blue:0.807 alpha:0.420];
		
		// set up some appearance on the grid view
		self.gridView.scrollElasticity = YES;
		
		// set up default values
		self.cellsPerRow = 3;
	}
	
	return self;
}


#pragma mark Data Source
/**
 * Returns the number of items that are in the given section.
 */
- (NSUInteger) gridView:(CNGridView *) gridView numberOfItemsInSection:(NSInteger) section {
	return 27;
}

/**
 * Returns a single item, given an index, section pair.
 */
- (CNGridViewItem *) gridView:(CNGridView *) gridView itemAtIndex:(NSInteger) index
					inSection:(NSInteger) section {
	// attempt to dequeue a cell; if not possible, allocate one
	static NSString *reuseIdentifier = @"TSLibraryOverviewLightTablecell";
	
	TSLibraryLightTableCell *cell = (TSLibraryLightTableCell *) [gridView dequeueReusableItemWithIdentifier:reuseIdentifier];
	if (cell == nil) {
		cell = [[TSLibraryLightTableCell alloc] initWithLayout:self.defaultLayout
											   reuseIdentifier:reuseIdentifier];
	}
	
	cell.hoverLayout = self.hoverLayout;
	cell.selectionLayout = self.selectionLayout;
	
	// set some data on it
	cell.itemTitle = @"cell lives here pls";
	cell.itemImage = [NSImage imageNamed:NSImageNameCaution];
	
	return cell;
}

#pragma mark Delegate
/**
 * An item was double-clicked; open the single image view.
 */
- (void) gridView:(CNGridView *) gridView didDoubleClickItemAtIndex:(NSUInteger) index
		inSection:(NSUInteger) section {
	
}

#pragma mark Sizing
/**
 * Recalculates the size of the individual grid cells.
 */
- (void) recalculateItemSize {
	CGFloat cellWidth = self.gridView.bounds.size.width / ((CGFloat) self.cellsPerRow);
	CGFloat cellHeight = cellWidth * 0.667;
	
	self.gridView.itemSize = NSMakeSize(cellWidth, cellHeight);
}

@end
