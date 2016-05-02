//
//  TSLibraryOverviewLightTableController.h
//  Avocado
//
//	Serves as a data source and delegate for the grid view on the light table
//	view.
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Cocoa/Cocoa.h>

/**
 * How to sort the results/images that are fetched.
 */
typedef NS_ENUM(NSUInteger, TSLibraryOverviewSortKey) {
	TSLibraryOverviewNoSort = -1,
	
	TSLibraryOverviewSortByDateShot = 1,
	TSLibraryOverviewSortByDateImported = 2,
	TSLibraryOverviewSortByFilename = 3,
};

@class TSLibraryLightTableCell, TSLibraryOverviewController;
@interface TSLibraryOverviewLightTableController : NSObject <NSCollectionViewDataSource, NSCollectionViewDelegate>

- (instancetype) initWithGridView:(NSCollectionView *) view;

@property (weak, nonatomic) TSLibraryOverviewController *overviewController;

@property (nonatomic) NSFetchRequest *fetchRequest;
@property (nonatomic) TSLibraryOverviewSortKey sortKey;

@property (nonatomic) NSUInteger cellsPerRow;

- (void) resizeCells;

#pragma mark Cell Actions
/*
 * All actions below are to be called from cell classes to achieve a certain
 * task. They should not be called from any other code.
 */
- (void) cellWasDoubleClicked:(TSLibraryLightTableCell *) cell;

@end
