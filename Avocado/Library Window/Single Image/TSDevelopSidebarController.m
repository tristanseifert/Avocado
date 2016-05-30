//
//  TSDevelopSidebarController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopSidebarController.h"
#import "TSDevelopImageViewerController.h"

#import "TSHumanModels.h"
#import "TSHistogramView.h"
#import "TSInspectorViewController.h"

#import "TSDevelopExposureInspector.h"
#import "TSDevelopHueInspector.h"
#import "TSDevelopDetailInspector.h"

// KVO context for the displayedImage property
static void *TSDisplayedImageKVO = &TSDisplayedImageKVO;
// KVO context for the image property
static void *TSImageKVO = &TSImageKVO;

@interface TSDevelopSidebarController ()

@property (nonatomic) IBOutlet TSHistogramView *mrHistogram;

@property (nonatomic) IBOutlet TSInspectorViewController *inspector;

@property (nonatomic) NSDictionary *restoredInspectorState;

@property (nonatomic) TSDevelopExposureInspector *inspectorExposure;
@property (nonatomic) TSDevelopHueInspector *inspectorHue;
@property (nonatomic) TSDevelopDetailInspector *inspectorDetail;

@end

@implementation TSDevelopSidebarController

/**
 * Initializes the view controller itself.
 */
- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopSidebarController" bundle:nil]) {
		// Set up exposure inspector
		self.inspectorExposure = [[TSDevelopExposureInspector alloc] init];
		// Set up HSL inspector
		self.inspectorHue = [[TSDevelopHueInspector alloc] init];
		// Set up detail inspector
		self.inspectorDetail = [[TSDevelopDetailInspector alloc] init];
		
		// Assign the re-rendering block
		void (^reRenderBlock)(void) = ^ {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.imageViewer processCurrentImage];
			});
		};
		
		self.inspectorExposure.settingsChangeBlock = reRenderBlock;
		self.inspectorHue.settingsChangeBlock = reRenderBlock;
		self.inspectorDetail.settingsChangeBlock = reRenderBlock;
		
		// Add KVO
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
	TSInspectorViewItem *inspect;
	
    [super viewDidLoad];
	
	// Prepare Mr. Histogram
	self.mrHistogram.quality = 4;
	
	// Add the previously created views to the inspector
	inspect = [TSInspectorViewItem itemWithContentController:self.inspectorExposure];
	[self.inspector addInspectorView:inspect];
	
	inspect = [TSInspectorViewItem itemWithContentController:self.inspectorHue];
	[self.inspector addInspectorView:inspect];
	
	inspect = [TSInspectorViewItem itemWithContentController:self.inspectorDetail];
	[self.inspector addInspectorView:inspect];
	
	// Add bindings for input image to inspectors
	[self.inspectorExposure bind:@"activeImage"
						toObject:self withKeyPath:@"image"
						 options:nil];
	[self.inspectorHue bind:@"activeImage"
				   toObject:self withKeyPath:@"image"
					options:nil];
	[self.inspectorDetail bind:@"activeImage"
					  toObject:self withKeyPath:@"image"
					   options:nil];
	
	// add bindings for displayed image to inspectors
	[self.inspectorExposure bind:@"renderedImage"
						toObject:self withKeyPath:@"displayedImage"
						 options:nil];
	[self.inspectorHue bind:@"renderedImage"
				   toObject:self withKeyPath:@"displayedImage"
					options:nil];
	[self.inspectorDetail bind:@"renderedImage"
					  toObject:self withKeyPath:@"displayedImage"
					   options:nil];
	
	// add bindings to Mr. Histogram
	[self.mrHistogram bind:@"image"
				  toObject:self withKeyPath:@"displayedImage"
				   options:nil];
	
	// restore state for inspector and its sub-panels
	if(self.restoredInspectorState != nil) {
		[self.inspector restoreWithState:self.restoredInspectorState];
	}
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
	// save inspector state
	NSDictionary *inspectorState = self.inspector.stateDict;
	[archiver encodeObject:inspectorState forKey:@"Develop.Sidebar.InspectorState"];
}

/**
 * Restores previously saved view state.
 */
- (void) restoreViewOptions:(NSKeyedUnarchiver *) unArchiver {
	self.restoredInspectorState = [unArchiver decodeObjectOfClass:[NSDictionary class]
														   forKey:@"Develop.Sidebar.InspectorState"];
}

@end
