//
//  TSLibraryDetailController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryDetailController.h"

#import "TSDevelopImageViewerController.h"
#import "TSDevelopSidebarController.h"
#import "TSMainLibraryWindowController.h"

#import "TSHumanModels.h"

/// minimum width of the sidebar
static const CGFloat TSEditSidebarMinWidth = 250.f;
/// maximum width of the sidebar
static const CGFloat TSEditSidebarMaxWidth = 450.f;

static void *TSImageKVO = &TSImageKVO;

@interface TSLibraryDetailController ()

@property (nonatomic) TSDevelopImageViewerController *imageController;
@property (nonatomic) TSDevelopSidebarController *sidebarController;

// restored split view state
@property (nonatomic) BOOL stateSidebarCollapsed;
@property (nonatomic) CGFloat stateSplitPosition;

@end

@implementation TSLibraryDetailController
@synthesize windowToolbar, windowController;

/**
 * Adds a few KVO
 */
- (instancetype) init {
	if(self = [super initWithNibName:@"TSLibraryDetail" bundle:nil]) {
		// add KVO for the image
		[self addObserver:self forKeyPath:@"image" options:0 context:TSImageKVO];
		
		// set up the sidebar controller
		self.imageController = [[TSDevelopImageViewerController alloc] init];
		self.sidebarController = [[TSDevelopSidebarController alloc] init];
		
		self.imageController.sidebar = self.sidebarController;
		self.sidebarController.imageViewer = self.imageController;
	}
	
	return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
	
	NSSplitViewItem *sidebar, *image;
	
	// add the image view
	image = [NSSplitViewItem splitViewItemWithViewController:self.imageController];
	image.collapseBehavior = NSSplitViewItemCollapseBehaviorPreferResizingSiblingsWithFixedSplitView;
	
	[self addSplitViewItem:image];
	
	// add the sidebar
	sidebar = [NSSplitViewItem sidebarWithViewController:self.sidebarController];
	sidebar.collapseBehavior = NSSplitViewItemCollapseBehaviorPreferResizingSiblingsWithFixedSplitView;
	
	sidebar.minimumThickness = TSEditSidebarMinWidth;
	sidebar.maximumThickness = TSEditSidebarMaxWidth;
	
	[self addSplitViewItem:sidebar];
	
	// restore the split view state
	NSSplitViewItem *sb = [self splitViewItemForViewController:self.sidebarController];
	sb.collapsed = self.stateSidebarCollapsed;
	
	if(self.stateSplitPosition >= 100.f) {
		[self.splitView setPosition:self.stateSplitPosition
				   ofDividerAtIndex:0];
	}
}

/**
 * Tells our containing window to hide the title bar and make the content view
 * span the entire size of the window.
 */
- (void) prepareWindowForAppearance:(NSWindow *) window {
	// set up the custom window appearance
	window.toolbar.visible = YES;
	window.titlebarAppearsTransparent = YES;
	window.movableByWindowBackground = YES;
	
	window.titleVisibility = NSWindowTitleHidden;
	
	NSUInteger styleMask = window.styleMask;
	window.styleMask = styleMask | NSFullSizeContentViewWindowMask;
}

#pragma mark State Restoration
/**
 * Saves any view options. Keys should be prefixed by some unique value.
 */
- (void) saveViewOptions:(NSKeyedArchiver *) archiver {
	[self.imageController saveViewOptions:archiver];
	[self.sidebarController saveViewOptions:archiver];
	
	// store position of first divider and collapsed state
	NSSplitViewItem *sb = [self splitViewItemForViewController:self.sidebarController];
	[archiver encodeBool:sb.isCollapsed forKey:@"Develop.SidebarCollapsed"];
	
	CGFloat pos = self.imageController.view.frame.size.width + 1;
	[archiver encodeDouble:pos forKey:@"Develop.SidebarPosition0"];
}

/**
 * Restores view options. Keys should be prefixed by some unique value.
 */
- (void) restoreViewOptions:(NSKeyedUnarchiver *) unArchiver {
	[self.imageController restoreViewOptions:unArchiver];
	[self.sidebarController restoreViewOptions:unArchiver];
	
	// restore split view position
	self.stateSidebarCollapsed = [unArchiver decodeBoolForKey:@"Develop.SidebarCollapsed"];
	
	self.stateSplitPosition = [unArchiver decodeDoubleForKey:@"Develop.SidebarPosition0"];
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
		self.imageController.image = self.image;
		self.sidebarController.image = self.image;
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark UI Actions
/**
 * Returns to the light table.
 */
- (IBAction) returnToLightTable:(id) sender {
	[self.windowController openLightTable];
}

/**
 * Toggles the sidebar.
 */
- (IBAction) toggleSidebar:(id) sender {
	NSSplitViewItem *sb = [self splitViewItemForViewController:self.sidebarController];
	sb.collapsed = !sb.collapsed;
}

/**
 * Forces a re-processing of the image.
 */
- (IBAction) developRefreshImage:(id) sender {
	DDLogVerbose(@"Refreshing image view");
	
	[self.imageController processCurrentImage];
}

@end
