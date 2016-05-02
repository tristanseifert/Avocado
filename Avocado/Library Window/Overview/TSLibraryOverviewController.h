//
//  TSLibraryOverviewController.h
//  Avocado
//
//	View controller that shows a list of catalogues and dates with images in
//	a split view on the left, shows a grid of images in the middle, and some
//	information about each image on the right.
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSMainLibraryContentViewController.h"

@interface TSLibraryOverviewController : TSMainLibraryContentViewController <NSSplitViewDelegate>

@property (nonatomic) IBOutlet NSSplitView *splitView;

@property (nonatomic) IBOutlet NSView *sidebarContainer;
@property (nonatomic) IBOutlet NSOutlineView *sidebar;

@property (nonatomic) IBOutlet NSCollectionView *lightTableView;

@property (nonatomic) IBOutlet NSPopover *viewOptionsPopover;

// view options
@property (nonatomic) CGFloat voThumbSize;
@property (nonatomic) NSInteger voSortKey;
@property (nonatomic) BOOL voShowFavoriting;

@property (nonatomic) BOOL voExtractThumbs;

@end
