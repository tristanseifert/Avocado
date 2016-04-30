//
//  TSLibraryOverviewController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryOverviewController.h"
#import "TSImportUIController.h"

#import "TSLibraryOverviewLightTableController.h"

#import <CNGridView/CNGridView.h>

@interface TSLibraryOverviewController ()

@property (nonatomic) TSImportUIController *importUI;

@property (nonatomic) TSLibraryOverviewLightTableController *lightTableController;

@end

@implementation TSLibraryOverviewController

- (void) viewDidLoad {
    [super viewDidLoad];
	
	// create controller
	self.lightTableController = [[TSLibraryOverviewLightTableController alloc] initWithGridView:self.lightTableView];
}

/**
 * When the view has appeared, perform a bit more configuration on the grid view.
 */
- (void) viewDidAppear {
	[super viewDidAppear];
	
	[self.lightTableController recalculateItemSize];
}


#pragma mark Library Window Content View Methods
/**
 * Tells our containing window to show the title bar, and make the content view
 * exclude the title bar, and show the title bar again.
 */
- (void) prepareWindowForAppearance:(NSWindow *) window {
	[super prepareWindowForAppearance:window];
	
	// set up the custom window appearance
	window.toolbar.visible = YES;
	window.titlebarAppearsTransparent = YES;
	window.movableByWindowBackground = NO;
	
	window.titleVisibility = NSWindowTitleVisible;
	
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

#pragma mark Split View Delegate

@end
