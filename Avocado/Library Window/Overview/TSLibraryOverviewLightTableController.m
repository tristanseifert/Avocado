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
#import "TSLibraryOverviewController.h"
#import "TSMainLibraryWindowController.h"

static void *TSCellsPerRowKVO = &TSCellsPerRowKVO;
static void *TSSortKeyKVO = &TSSortKeyKVO;

@interface TSLibraryOverviewLightTableController ()

@property (nonatomic) NSArray<TSLibraryImage *> *imagesToShow;
@property (nonatomic) NSCollectionView *gridView;

- (void) applySortDescriptors;
- (void) refetchImages;
- (void) imageDidImportNotification:(NSNotification *) n;

- (void) scrollViewSizeChanged:(NSNotification *) n;

@end

@implementation TSLibraryOverviewLightTableController

/**
 * Initialises the controller.
 */
- (instancetype) initWithGridView:(NSCollectionView *) view {
	if(self = [super init]) {
		self.gridView = view;
		
		// we're both its delegate and its data source
		self.gridView.dataSource = self;
		self.gridView.delegate = self;
		
		// register cell
		[self.gridView registerClass:[TSLibraryLightTableCell class] forItemWithIdentifier:@"ImageCell"];
		
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
		
		// set up some default values
		self.cellsPerRow = 2;
		
		self.sortKey = TSLibraryOverviewNoSort;
		
		// add KVO observer for some keys
		[self addObserver:self forKeyPath:@"cellsPerRow" options:0
				  context:TSCellsPerRowKVO];
		
		[self addObserver:self forKeyPath:@"sortKey" options:0
				  context:TSSortKeyKVO];
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

#pragma mark Collection View Data Source
/**
 * Returns the number of images that are in the image browser.
 */
- (NSInteger) collectionView:(NSCollectionView *) collectionView numberOfItemsInSection:(NSInteger) section {
	return self.imagesToShow.count * 100;
}

/**
 * Returns an item for the given index.
 */
- (NSCollectionViewItem *) collectionView:(NSCollectionView *) collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *) indexPath {
	// get a cell
	TSLibraryLightTableCell *cell = [self.gridView makeItemWithIdentifier:@"ImageCell" forIndexPath:indexPath];
	cell.controller = self;
	
	// set the image
	NSUInteger idx = [indexPath indexAtPosition:1];
	
	cell.representedObject = self.imagesToShow[idx % self.imagesToShow.count];
	cell.imageSequence = idx + 1;
	
	return cell;
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

#pragma mark Collection View Delegate

#pragma mark KVO
/**
 * Handles KVO notifications.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath
					   ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	// cellsPerRow changed
	if(context == TSCellsPerRowKVO) {
		[self resizeCells];
	}
	// sort key changed
	else if(context == TSSortKeyKVO) {
		[self applySortDescriptors];
		[self refetchImages];
	}
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
	
	// update its sort descriptors
	[self applySortDescriptors];
	
	// EGGsecute it
	[self refetchImages];
}

/**
 * Executes the fetch request, then updates the image view
 */
- (void) refetchImages {
	// ensure we have a valid fetch request
	if(self.fetchRequest == nil) return;
	
	// execute the request and reload data
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
//		DDLogVerbose(@"did the import thing: %@", n);
		
//		[self refetchImages];
	});
}

/**
 * Applies the appropriate sort descriptors.
 */
- (void) applySortDescriptors {
	NSSortDescriptor *sd = nil;
	
	switch(self.sortKey) {
		// no sort
		case TSLibraryOverviewNoSort:
			self.fetchRequest.sortDescriptors = nil;
			break;
			
		// sort by date shot
		case TSLibraryOverviewSortByDateShot:
			sd = [NSSortDescriptor sortDescriptorWithKey:@"dateShot" ascending:NO];
			self.fetchRequest.sortDescriptors = @[sd];
			break;
			
		// sort by date imported
		case TSLibraryOverviewSortByDateImported:
			sd = [NSSortDescriptor sortDescriptorWithKey:@"dateImported" ascending:NO];
			self.fetchRequest.sortDescriptors = @[sd];
			break;
			
		// sort by filename
		case TSLibraryOverviewSortByFilename:
			sd = [NSSortDescriptor sortDescriptorWithKey:@"fileUrl" ascending:NO];
			self.fetchRequest.sortDescriptors = @[sd];
			break;
	}
}

#pragma mark Resizing
/**
 * resizes the cells.
 */
- (void) resizeCells {
	NSCollectionViewFlowLayout *layout = (NSCollectionViewFlowLayout *) self.gridView.collectionViewLayout;
	
	// calculate per cell size
	CGFloat cellWidth = floorf(self.gridView.frame.size.width / ((CGFloat) self.cellsPerRow));
	CGFloat cellHeight = ceilf(cellWidth * 1.25);
	
	layout.itemSize = NSMakeSize(cellWidth, cellHeight);
	
//	DDLogInfo(@"New item size: %@", NSStringFromSize(layout.itemSize));
	
	// force the thumbnails to be re-created
	[[NSNotificationCenter defaultCenter] postNotificationName:TSLibraryLightTableInvalidateThumbsNotificationName object:nil];
}

/**
 * The frame of the scroll view containing the grid changed, so update the cell
 * size.
 */
- (void) scrollViewSizeChanged:(NSNotification *) n {
//	DDLogVerbose(@"Size of scroll view changed: %@", NSStringFromRect(self.gridView.enclosingScrollView.frame));
	
	[self resizeCells];
}

#pragma mark Cell Actions
/**
 * When a cell is double clicked, the editing view controller is to be displayed
 * with the selected image as its content.
 */
- (void) cellWasDoubleClicked:(TSLibraryLightTableCell *) cell {
	TSLibraryImage *image = cell.representedObject;
	
	[self.overviewController.windowController openEditorForImage:image];
}

@end
