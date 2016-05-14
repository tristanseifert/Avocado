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

@end

@implementation TSDevelopSidebarController

/**
 * Initializes the view controller itself.
 */
- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopSidebarController" bundle:nil]) {
		// set up the inspectors
		TSDevelopExposureInspector *exp = [[TSDevelopExposureInspector alloc] init];
		
		self.inspectorExposure = [TSInspectorViewItem itemWithContentController:exp];
	}
	
	return self;
}

/**
 * Sets some stuff up when the view controller has loaded.
 */
- (void) viewDidLoad {
    [super viewDidLoad];
	
	// adds the previously created views to the inspector
//	[self.stackView addView:self.inspectorExposure.view inGravity:NSStackViewGravityCenter];
	[self.inspector addInspectorView:self.inspectorExposure];
}

@end
