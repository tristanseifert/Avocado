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

@interface TSDevelopSidebarController ()

@property (nonatomic) IBOutlet TSHistogramView *mrHistogram;

@end

@implementation TSDevelopSidebarController

/**
 * Initializes the view controller itself.
 */
- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopSidebarController" bundle:nil]) {
		
	}
	
	return self;
}

/**
 * Sets some stuff up when the view controller has loaded.
 */
- (void) viewDidLoad {
    [super viewDidLoad];
	
	// set up Mr. Histogram
	self.mrHistogram.quality = 4;
}

@end
