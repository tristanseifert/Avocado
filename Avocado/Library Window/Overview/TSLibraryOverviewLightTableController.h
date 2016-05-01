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

@interface TSLibraryOverviewLightTableController : NSObject <NSCollectionViewDataSource, NSCollectionViewDelegate>

- (instancetype) initWithGridView:(NSCollectionView *) view;

@property (nonatomic) NSFetchRequest *fetchRequest;

@property (nonatomic) NSUInteger cellsPerRow;

- (void) resizeCells;

@end
