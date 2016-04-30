//
//  TSLibraryOverviewController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryOverviewController.h"

@interface TSLibraryOverviewController ()

@end

@implementation TSLibraryOverviewController

- (void) viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


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
	
}

@end
