//
//  TSMainLibraryWindowController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSMainLibraryWindowController.h"

#import "TSLibraryOverviewController.h"
#import "TSLibraryDetailController.h"

@interface TSMainLibraryWindowController ()

@property (nonatomic) TSLibraryOverviewController *vcOverview;
@property (nonatomic) TSLibraryDetailController *vcEdit;

@end

@implementation TSMainLibraryWindowController

/**
 * Applies some customizations to the window style.
 */
- (void) windowDidLoad {
    [super windowDidLoad];
    
	// set up the custom UI
	self.window.toolbar.visible = NO;
	self.window.titlebarAppearsTransparent = YES;
	self.window.movableByWindowBackground = YES;
	
	self.window.titleVisibility = NSWindowTitleHidden;
	
	// add full size content mask
	NSUInteger styleMask = self.window.styleMask;
	self.window.styleMask = styleMask | NSFullSizeContentViewWindowMask;
	
	// create the various controllers
	self.vcOverview = [[TSLibraryOverviewController alloc] initWithNibName:@"TSLibraryOverview" bundle:nil];
	self.vcEdit = [[TSLibraryDetailController alloc] initWithNibName:@"TSLibraryDetail" bundle:nil];
	
	// set content
	self.contentViewController = self.vcOverview;
}

@end
