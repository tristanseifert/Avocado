//
//  TSInspectorView.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSInspectorView.h"

@interface TSInspectorView ()

- (void) commonInit;

//@property (nonatomic) NSStackView *stackView;

@property (nonatomic) NSLayoutConstraint *widthConstraint;

/// array of inspector panels
@property (nonatomic) NSMutableArray<TSInspectorViewItem *> *panels;

- (void) TSAddWidthConstraint;

@end

@implementation TSInspectorView

#pragma mark Initialization
- (instancetype) initWithFrame:(NSRect)frameRect {
	if(self = [super initWithFrame:frameRect]) {
		[self commonInit];
	}
	
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)coder {
	if(self = [super initWithCoder:coder]) {
		[self commonInit];
	}
	
	return self;
}

/**
 * Sets up the stack view to have the settings we desire.
 */
- (void) commonInit {
//	self.wantsLayer = YES;
//	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	self.orientation = NSUserInterfaceLayoutOrientationVertical;
	
	self.alignment = NSLayoutAttributeLeading;
	self.distribution = NSStackViewDistributionFill;
	
	self.detachesHiddenViews = YES;
	self.spacing = 0.f;
	
	self.panels = [NSMutableArray new];
}

/**
 * Enable vibrancy for descendants.
 */
- (BOOL) allowsVibrancy {
	return YES;
}

#pragma mark Sizing
/**
 * Causes a constraint to be added.
 */
- (void) viewDidMoveToWindow {
	[super viewDidMoveToWindow];
	
	[self TSAddWidthConstraint];
}

/**
 * Causes a constraint to be added.
 */
- (void) viewDidMoveToSuperview {
	[super viewDidMoveToSuperview];

	[self TSAddWidthConstraint];
}

/**
 * Adds the width constraint so that it fills the width of the scroll
 * view that the view is in.
 */
- (void) TSAddWidthConstraint {
	if(self.superview != nil && self.enclosingScrollView) {
		NSLayoutConstraint *c;
		NSScrollView *scroll = self.enclosingScrollView;
		
		// build the equal widths constraint; priority = 1000
		c = [NSLayoutConstraint constraintWithItem:scroll
										 attribute:NSLayoutAttributeWidth
										 relatedBy:NSLayoutRelationEqual
											toItem:self
										 attribute:NSLayoutAttributeWidth
										multiplier:1.f constant:0.f];
		c.priority = NSLayoutPriorityRequired;
		
		// add the constraint
		self.widthConstraint = c;
		[scroll addConstraint:self.widthConstraint];
	}
	
	DDLogVerbose(@"Frame: %@", NSStringFromRect(self.frame));
}

/**
 * Removes the constraint, just before the view is removed from its
 * superview.
 */
- (void) viewWillMoveToSuperview:(NSView *) newSuperview {
	if(self.superview != nil && self.widthConstraint != nil) {
		[self.enclosingScrollView removeConstraint:self.widthConstraint];
		
		self.widthConstraint = nil;
	}
}

#pragma mark Inspector Handling
/**
 * Appends an inspector to the end of the view.
 */
- (void) addInspectorView:(TSInspectorViewItem *) controller {
	[self.panels addObject:controller];
	
	NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 300, 25)];
	button.title = @"test";
	
	[self addView:button inGravity:NSStackViewGravityCenter];
}

/**
 * Inserts an inspector view at the given index.
 */
- (void) insertInspectorView:(TSInspectorViewItem *) controller atIndex:(NSUInteger) index {
	[self.panels insertObject:controller atIndex:index];
	
	[self insertView:controller.view atIndex:index inGravity:NSStackViewGravityCenter];
}


/**
 * Removes a previously added inspector view.
 */
- (void) removeInspectorView:(TSInspectorViewItem *) controller {
	[self.panels removeObject:controller];
	
	[self removeView:controller.view];
}

@end
