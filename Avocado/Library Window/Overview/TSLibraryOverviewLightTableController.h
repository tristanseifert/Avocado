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

typedef NS_ENUM(NSUInteger, TSLibraryOverviewSortKey) {
	TSLibraryOverviewNoSort = -1,
	
	TSLibraryOverviewSortByDateShot = 1,
	TSLibraryOverviewSortByDateImported = 2,
	TSLibraryOverviewSortByFilename = 3,
};

@interface TSLibraryOverviewLightTableController : NSObject <NSCollectionViewDataSource, NSCollectionViewDelegate>

- (instancetype) initWithGridView:(NSCollectionView *) view;

@property (nonatomic) NSFetchRequest *fetchRequest;
@property (nonatomic) TSLibraryOverviewSortKey sortKey;

@property (nonatomic) NSUInteger cellsPerRow;

- (void) resizeCells;

@end
