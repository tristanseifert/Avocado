//
//  TSLibraryOverviewController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryOverviewController.h"
#import "TSImportUIController.h"
#import "TSHumanModels.h"
#import "TSLibraryOverviewLightTableController.h"

#import <MagicalRecord/MagicalRecord.h>

static void *TSThumbSizeKVO = &TSThumbSizeKVO;
static void *TSSortKeyKVO = &TSSortKeyKVO;

@interface TSLibraryOverviewController ()

@property (nonatomic) TSImportUIController *importUI;

@property (nonatomic) TSLibraryOverviewLightTableController *lightTableController;

- (void) updateSorting;

@end

@implementation TSLibraryOverviewController
@synthesize windowToolbar, windowController;

/**
 * Initializes some defaults and KVO.
 */
- (instancetype) init {
	if(self = [super initWithNibName:@"TSLibraryOverview" bundle:nil]) {
		// set up a few defaults
		self.voThumbSize = 2.f;
		self.voSortKey = 1;
		self.voShowFavoriting = YES;
		
		self.voExtractThumbs = YES;
		
		// add a few KVO observers for the view options
		[self addObserver:self forKeyPath:@"voThumbSize" options:0
				  context:TSThumbSizeKVO];
		[self addObserver:self forKeyPath:@"voSortKey" options:0
				  context:TSSortKeyKVO];
	}
	
	return self;
}

/**
 * Initializes the view, as well as the library overview controller.
 */
- (void) viewDidLoad {
    [super viewDidLoad];
	
	// create controller
	self.lightTableController = [[TSLibraryOverviewLightTableController alloc] initWithGridView:self.lightTableView];
	self.lightTableController.overviewController = self;
	
	self.lightTableController.fetchRequest = [TSLibraryImage MR_createFetchRequest];
	
	// resize cells and update sort key
	self.lightTableController.cellsPerRow = (NSUInteger) self.voThumbSize;
	[self.lightTableController resizeCells];
	
	[self updateSorting];
}

/**
 * When the view has appeared, perform a bit more configuration on the grid view.
 */
- (void) viewDidAppear {
	[super viewDidAppear];
	
	[self.lightTableController resizeCells];
}

#pragma mark KVO
/**
 * KVO handler, used to update the view options things.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath
					   ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	// thumb size changed
	if(context == TSThumbSizeKVO) {
		self.lightTableController.cellsPerRow = (NSUInteger) self.voThumbSize;
	}
	// sort key changed
	else if(context == TSSortKeyKVO) {
		[self updateSorting];
	}
	// any other KVO change
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

/**
 * Updates how the view is sorted.
 */
- (void) updateSorting {
	if(self.voSortKey == 1) {
		self.lightTableController.sortKey = TSLibraryOverviewSortByDateShot;
	} else if(self.voSortKey == 2) {
		self.lightTableController.sortKey = TSLibraryOverviewSortByDateImported;
	} else if(self.voSortKey == 3) {
		self.lightTableController.sortKey = TSLibraryOverviewSortByFilename;
	}
}

#pragma mark Library Window Content View Methods
/**
 * Tells our containing window to show the title bar, and make the content view
 * exclude the title bar, and show the title bar again.
 */
- (void) prepareWindowForAppearance:(NSWindow *) window {	
	// set up the custom window appearance
	window.toolbar.visible = YES;
	window.titlebarAppearsTransparent = NO;
	window.movableByWindowBackground = NO;
	
	window.titleVisibility = NSWindowTitleHidden;
	
	NSUInteger styleMask = window.styleMask;
//	window.styleMask = styleMask & (~NSFullSizeContentViewWindowMask);
	window.styleMask = styleMask | NSFullSizeContentViewWindowMask;
}

#pragma mark UI Actions
/**
 * Opens the import dialog, that allows selection of a directory of files that
 * shall be imported.
 */
- (IBAction) showImportDialog:(id) sender {
	if(self.importUI == nil) {
		self.importUI = [TSImportUIController new];
	}
	
	[self.importUI presentAsSheetOnWindow:self.view.window];
}

/**
 * Displays the view options popover at the origin of the sender.
 */
- (IBAction) showViewOptions:(id) sender {
	if([sender isKindOfClass:[NSView class]]) {
		NSView *theView = (NSView *) sender;
		
		[self.viewOptionsPopover showRelativeToRect:NSZeroRect
											 ofView:theView
									  preferredEdge:NSRectEdgeMaxX];
	} else {
		DDLogWarn(@"Showing view options with a sender that's not a view; this shouldn't happen");
	}
}

#pragma mark Split View Delegate
/**
 * Constrains the left sidebar to be at least 150px, but no larger than 400px.
 */
- (CGFloat) splitView:(NSSplitView *) splitView constrainSplitPosition:(CGFloat) proposedPosition
		  ofSubviewAt:(NSInteger) dividerIndex {
	if(dividerIndex == 0) {
		// minimum size: 150px
		if(proposedPosition <= 150.f) {
			return 150.f;
		}
		// maximum size: 400px
		else if(proposedPosition >= 400.f) {
			return 400.f;
		}
	}
	
	return proposedPosition;
}

/**
 * When the split view has resized the subviews, initiate resizing of the grid
 * cells.
 */
- (void)splitViewDidResizeSubviews:(NSNotification *) notification {

}

#pragma mark View Options
/**
 * Saves view options. Keys should be prefixed by some unique value.
 */
- (void) saveViewOptions:(NSKeyedArchiver *) archiver {
	[archiver encodeDouble:self.voThumbSize forKey:@"LightTable.ThumbSize"];
	[archiver encodeInteger:self.voSortKey forKey:@"LightTable.SortKey"];
	[archiver encodeBool:self.voShowFavoriting forKey:@"LightTable.ShowFavoriteControls"];
	
	[archiver encodeBool:self.voExtractThumbs forKey:@"LightTable.ExtractThumbs"];
}

/**
 * Restores view options. Keys should be prefixed by some unique value.
 */
- (void) restoreViewOptions:(NSKeyedUnarchiver *) unArchiver {
	self.voThumbSize = [unArchiver decodeDoubleForKey:@"LightTable.ThumbSize"];
	self.voSortKey = [unArchiver decodeIntegerForKey:@"LightTable.SortKey"];
	self.voShowFavoriting = [unArchiver decodeBoolForKey:@"LightTable.ShowFavoriteControls"];
	
	self.voExtractThumbs = [unArchiver decodeBoolForKey:@"LightTable.ExtractThumbs"];
}

@end
