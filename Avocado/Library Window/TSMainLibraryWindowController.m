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
	
	// create the various controllers
	self.vcOverview = [[TSLibraryOverviewController alloc] initWithNibName:@"TSLibraryOverview" bundle:nil];
	self.vcEdit = [[TSLibraryDetailController alloc] initWithNibName:@"TSLibraryDetail" bundle:nil];
	
	// set content
	self.contentViewController = self.vcOverview;
	
	[((TSMainLibraryContentViewController *) self.contentViewController) prepareWindowForAppearance:self.window];
}

@end
