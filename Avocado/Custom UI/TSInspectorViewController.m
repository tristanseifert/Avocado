//
//  TSInspectorView.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSInspectorViewController.h"

@interface TSInspectorViewController ()

- (void) commonInit;

@property (nonatomic) IBOutlet NSStackView *stackView;

@property (nonatomic) NSLayoutConstraint *widthConstraint;
@property (nonatomic) NSLayoutConstraint *heightConstraint;

/// array of inspector panels
@property (nonatomic) NSMutableArray<TSInspectorViewItem *> *panels;

- (void) addWidthConstraint;

@end

@implementation TSInspectorViewController

#pragma mark Initialization
/**
 * Sets up stuff when the controller is created.
 */
- (void) awakeFromNib {
	[super awakeFromNib];
	
	[self commonInit];
}

/**
 * Sets up the stack view to have the settings we desire.
 */
- (void) commonInit {
	self.stackView.wantsLayer = YES;
	self.stackView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;

	// set up stack view properties
	self.stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
	
	self.stackView.alignment = NSLayoutAttributeLeading;
	self.stackView.distribution = NSStackViewDistributionFill;
	
	self.stackView.detachesHiddenViews = YES;
	self.stackView.spacing = 0.f;
	
	// we strongly hug the sides of the views it contains
	[self.stackView setHuggingPriority:NSLayoutPriorityDefaultLow
						forOrientation:NSLayoutConstraintOrientationHorizontal];
	
	// we shall grow and shrink as its internal views grow, are added, or are removed
	[self.stackView setHuggingPriority:NSLayoutPriorityDefaultHigh
						forOrientation:NSLayoutConstraintOrientationVertical];
	
	// set up panels
	self.panels = [NSMutableArray new];
	
	// add constraint
	[self addWidthConstraint];
}

#pragma mark Sizing
/**
 * Adds the width constraint so that it fills the width of the scroll
 * view that the view is in.
 */
- (void) addWidthConstraint {
	if(self.stackView.superview != nil && self.stackView.enclosingScrollView) {
		NSLayoutConstraint *c;
		NSScrollView *scroll = self.stackView.enclosingScrollView;
		
		// build the equal widths constraint; priority = 1000
		c = [NSLayoutConstraint constraintWithItem:self.stackView
										 attribute:NSLayoutAttributeWidth
										 relatedBy:NSLayoutRelationEqual
											toItem:scroll.contentView
										 attribute:NSLayoutAttributeWidth
										multiplier:1.f constant:0.f];
		c.priority = NSLayoutPriorityRequired;
		
		self.widthConstraint = c;
		[scroll addConstraint:self.widthConstraint];
		
		
//		// build the greater than or equal height constraint; priority = 1000
//		c = [NSLayoutConstraint constraintWithItem:self.stackView
//										 attribute:NSLayoutAttributeHeight
//										 relatedBy:NSLayoutRelationGreaterThanOrEqual
//											toItem:scroll.contentView
//										 attribute:NSLayoutAttributeHeight
//										multiplier:1.f constant:0.f];
//		c.priority = NSLayoutPriorityRequired;
//		
//		self.heightConstraint = c;
//		[scroll addConstraint:self.heightConstraint];
	}
}

#pragma mark Inspector Handling
/**
 * Appends an inspector to the end of the view.
 */
- (void) addInspectorView:(TSInspectorViewItem *) controller {
	[self.panels addObject:controller];
	
	[self.stackView addView:controller.view inGravity:NSStackViewGravityCenter];
}

/**
 * Inserts an inspector view at the given index.
 */
- (void) insertInspectorView:(TSInspectorViewItem *) controller atIndex:(NSUInteger) index {
	[self.panels insertObject:controller atIndex:index];
	
	[self.stackView insertView:controller.view atIndex:index inGravity:NSStackViewGravityCenter];
}


/**
 * Removes a previously added inspector view.
 */
- (void) removeInspectorView:(TSInspectorViewItem *) controller {
	[self.panels removeObject:controller];
	
	[self.stackView removeView:controller.view];
}

@end
