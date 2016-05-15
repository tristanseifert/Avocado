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

// KVO context for the displayedImage property
static void *TSDisplayedImageKVO = &TSDisplayedImageKVO;
// KVO context for the image property
static void *TSImageKVO = &TSImageKVO;

@interface TSDevelopSidebarController ()

@property (nonatomic) IBOutlet TSHistogramView *mrHistogram;

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
		
		// add KVO
		[self addObserver:self forKeyPath:@"displayedImage"
				  options:0 context:TSDisplayedImageKVO];
		[self addObserver:self forKeyPath:@"image"
				  options:0 context:TSImageKVO];
	}
	
	return self;
}

/**
 * Sets some stuff up when the view controller has loaded.
 */
- (void) viewDidLoad {
    [super viewDidLoad];
	
	// prepare Mr. Histogram
	self.mrHistogram.quality = 4;
	
	// add the previously created views to the inspector
	[self.inspector addInspectorView:self.inspectorExposure];
	[self.inspector addInspectorView:self.inspectorWhiteBal];
}

#pragma mark KVO
/**
 * Handles KVO, including that for the image changing.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath
					   ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	// the displayed image property changed
	if(context == TSDisplayedImageKVO) {
		self.mrHistogram.image = self.displayedImage;
	}
	// input image changed
	else if(context == TSImageKVO) {
	
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark State Restoration
/**
 * Saves view state.
 */
- (void) saveViewOptions:(NSKeyedArchiver *) archiver {
	
}

/**
 * Restores previously saved view state.
 */
- (void) restoreViewOptions:(NSKeyedUnarchiver *) unArchiver {
	
}

@end
