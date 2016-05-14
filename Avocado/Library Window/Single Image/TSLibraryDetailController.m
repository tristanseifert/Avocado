//
//  TSLibraryDetailController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryDetailController.h"

#import "TSHistogramView.h"

#import "TSHumanModels.h"
#import "TSMainLibraryWindowController.h"

static void *TSImageKVO = &TSImageKVO;

@interface TSLibraryDetailController ()

@property (nonatomic) NSImage *displayedImage;

@property (nonatomic) NSView *imageDisplayView;

- (void) updateImageView;

@end

@implementation TSLibraryDetailController

/**
 * Adds a few KVO
 */
- (instancetype) init {
	if(self = [super initWithNibName:@"TSLibraryDetail" bundle:nil]) {
		// add KVO for the image
		[self addObserver:self forKeyPath:@"image" options:0 context:TSImageKVO];
	}
	
	return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
	
	// set up image view
	self.imageDisplayView = [[NSView alloc] initWithFrame:NSZeroRect];
	self.imageDisplayView.wantsLayer = YES;
	
	self.scrollView.documentView = self.imageDisplayView;
}

/**
 * Tells our containing window to hide the title bar and make the content view
 * span the entire size of the window.
 */
- (void) prepareWindowForAppearance:(NSWindow *) window {
	[super prepareWindowForAppearance:window];
	
	// set up the custom window appearance
	window.toolbar.visible = YES;
	window.titlebarAppearsTransparent = YES;
	window.movableByWindowBackground = YES;
	
	window.titleVisibility = NSWindowTitleHidden;
	
	NSUInteger styleMask = window.styleMask;
	window.styleMask = styleMask | NSFullSizeContentViewWindowMask;
}

#pragma mark KVO
/**
 * Handles KVO, including that for the image changing.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath
					   ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	// the image property changed
	if(context == TSImageKVO) {
		DDLogVerbose(@"Changed image: %@", self.image.fileUrl);
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Image Handling
/**
 * Handles the image.
 */
- (void) updateImageView {
	// set image, pls.
	self.imageDisplayView.layer.contents = self.displayedImage;
	
	// update size of the image view and content view of the scroll view
	NSSize imageSize = self.displayedImage.size;
	
	self.imageDisplayView.frame = (NSRect) {
		.size = imageSize,
		.origin = NSZeroPoint
	};
	self.imageDisplayView.layer.frame = self.imageDisplayView.frame;

	((NSView *) self.scrollView.documentView).frame = self.imageDisplayView.frame;
	
	// zoom out to fit the image
}

#pragma mark Split View Delegate
/**
 * Constrains the right sidebar to be at least 150px, but no larger than 400px.
 */
- (CGFloat) splitView:(NSSplitView *) splitView constrainSplitPosition:(CGFloat) proposedPosition ofSubviewAt:(NSInteger) dividerIndex {
	CGFloat width = splitView.bounds.size.width;
	
	if(dividerIndex == 0) {
		if(proposedPosition <= (width - 48.f)) {
			return (width - 48.f);
		} else if(proposedPosition > (width - 48.f)) {
			return 0.f;
		}
	}
	
	// we should not get down here
	return proposedPosition;
}

/**
 * Constrains the minimum coordinate of the divider.
 */
- (CGFloat) splitView:(NSSplitView *) splitView constrainMinCoordinate:(CGFloat) proposedMinimumPosition ofSubviewAt:(NSInteger) dividerIndex {
	CGFloat width = splitView.bounds.size.width;
	
	if(dividerIndex == 0) {
		return (width - 48.f);
	}
	
	// we should not get down here
	return proposedMinimumPosition;
}

/**
 * Constrains the maximum coordinate of the divider.
 */
- (CGFloat) splitView:(NSSplitView *) splitView constrainMaxCoordinate:(CGFloat) proposedMaximumPosition ofSubviewAt:(NSInteger) dividerIndex {
	CGFloat width = splitView.bounds.size.width;
	
	if(dividerIndex == 0) {
		return width;
	}
	
	// we should not get down here
	return proposedMaximumPosition;
	
}

/**
 * Allow the right sidebar to be completely collapsed.
 */
- (BOOL) splitView:(NSSplitView *) splitView canCollapseSubview:(NSView *) subview {
	if([subview isEqualTo:self.sidebarView]) {
		return YES;
	}
	
	return NO;
}

/**
 * When double-clicking on the first divider, allow hiding of the right  sidebar
 * with the palettes.
 */
- (BOOL) splitView:(NSSplitView *) splitView shouldCollapseSubview:(NSView *) subview forDoubleClickOnDividerAtIndex:(NSInteger) dividerIndex {
	if(dividerIndex == 0 && [subview isEqualTo:self.sidebarView]) {
		return YES;
	}
	
	return NO;
}

#pragma mark UI Actions
/**
 * Returns to the light table.
 */
- (IBAction) returnToLightTable:(id) sender {
	[self.windowController openLightTable];
}

@end
