//
//  TSDevelopSidebarController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopSidebarController.h"

#import "TSHumanModels.h"
#import "TSHistogramView.h"
#import "TSInspectorViewController.h"

#import "TSDevelopExposureInspector.h"

@interface TSDevelopSidebarController ()

@property (nonatomic) IBOutlet TSInspectorViewController *inspector;

@property (nonatomic) TSInspectorViewItem *inspectorExposure;
@property (nonatomic) TSInspectorViewItem *inspectorWhiteBal;

@end

@implementation TSDevelopSidebarController

/**
 * Initializes the view controller itself.
 */
- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopSidebarController" bundle:nil]) {
		// set up exposure inspector
		TSDevelopExposureInspector *exp = [[TSDevelopExposureInspector alloc] init];
		self.inspectorExposure = [TSInspectorViewItem itemWithContentController:exp
																	   expanded:YES];
		
		// set up white balance inspector
		TSDevelopExposureInspector *wb = [[TSDevelopExposureInspector alloc] init];
		wb.title = @"White Balance";
		self.inspectorWhiteBal = [TSInspectorViewItem itemWithContentController:wb
																	   expanded:YES];
	}
	
	return self;
}

/**
 * Sets some stuff up when the view controller has loaded.
 */
- (void) viewDidLoad {
    [super viewDidLoad];
	
	// add the previously created views to the inspector
	[self.inspector addInspectorView:self.inspectorExposure];
	[self.inspector addInspectorView:self.inspectorWhiteBal];
}

@end
