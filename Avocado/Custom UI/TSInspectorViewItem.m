//
//  TSInspectorViewItem.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSInspectorViewItem.h"

#import "TSVibrantView.h"

/// height of the title bar of the inspector, in points
static const CGFloat TSInspectorTitleBarHeight = 25.f;

@interface TSInspectorViewItem ()

@property (nonatomic, strong) NSViewController *content;

// title bar for the inspector pane
@property (nonatomic) NSView *titleBar;
// override the view property as a stack view
@property (nonatomic) NSStackView *view;

@end

@implementation TSInspectorViewItem
@dynamic view;

/**
 * Sets up an inspector view item, using the given view controller as the
 * content.
 */
+ (instancetype) itemWithContentController:(NSViewController *) content {
	TSInspectorViewItem *i = [[TSInspectorViewItem alloc] init];
	
	i.content = content;
	
	// done
	return i;
}

#pragma mark View Handling
/**
 * Sets up a custom view.
 */
- (void) loadView {
	self.view = [[NSStackView alloc] initWithFrame:NSZeroRect];
	
	self.view.wantsLayer = YES;
	self.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	self.view.layer.backgroundColor = [NSColor greenColor].CGColor;
	
	self.view.spacing = 0.f;
	self.view.orientation = NSUserInterfaceLayoutOrientationVertical;
	
	self.view.alignment = NSLayoutAttributeLeading;
	self.view.distribution = NSStackViewDistributionFill;
}

/**
 * Once the view has loaded, add the content controller as a child.
 */
- (void) viewDidLoad {
	NSLayoutConstraint *c;
	
	[super viewDidLoad];
	
	// add the title view
	self.titleBar = [[TSVibrantView alloc] initWithFrame:NSZeroRect];
	self.titleBar.wantsLayer = YES;
	
	self.titleBar.layer.backgroundColor = [NSColor redColor].CGColor;
	
	[self.view addView:self.titleBar
			 inGravity:NSStackViewGravityTop];
	
	// set up size constraints for the title bar
	c = [NSLayoutConstraint constraintWithItem:self.titleBar
									 attribute:NSLayoutAttributeHeight
									 relatedBy:NSLayoutRelationEqual
										toItem:nil
									 attribute:NSLayoutAttributeNotAnAttribute
									multiplier:0.f constant:TSInspectorTitleBarHeight];
	c.priority = NSLayoutPriorityRequired;
	[self.titleBar addConstraint:c];
	
	// align the title bar to the top, leading and trailing of the parent
	c = [NSLayoutConstraint constraintWithItem:self.titleBar
									 attribute:NSLayoutAttributeLeading
									 relatedBy:NSLayoutRelationEqual
										toItem:self.view
									 attribute:NSLayoutAttributeLeading
									multiplier:1.f constant:0];
	c.priority = NSLayoutPriorityDefaultHigh;
	[self.view addConstraint:c];
	
	c = [NSLayoutConstraint constraintWithItem:self.titleBar
									 attribute:NSLayoutAttributeTrailing
									 relatedBy:NSLayoutRelationEqual
										toItem:self.view
									 attribute:NSLayoutAttributeTrailing
									multiplier:1.f constant:0];
	c.priority = NSLayoutPriorityDefaultHigh;
	[self.view addConstraint:c];
	
	c = [NSLayoutConstraint constraintWithItem:self.titleBar
									 attribute:NSLayoutAttributeTop
									 relatedBy:NSLayoutRelationEqual
										toItem:self.view
									 attribute:NSLayoutAttributeTop
									multiplier:1.f constant:0];
	c.priority = NSLayoutPriorityDefaultHigh;
	[self.view addConstraint:c];
	
	
	
	// add the child view controller
	[self addChildViewController:self.content];
	[self.view addView:self.content.view
			 inGravity:NSStackViewGravityCenter];
	
	// add constraints for the child controller to match its size
	c = [NSLayoutConstraint constraintWithItem:self.content.view
									 attribute:NSLayoutAttributeHeight
									 relatedBy:NSLayoutRelationEqual
										toItem:nil
									 attribute:NSLayoutAttributeNotAnAttribute
									multiplier:0.f
									  constant:self.content.preferredContentSize.height];
	c.priority = NSLayoutPriorityRequired;
	[self.content.view addConstraint:c];
	
	// now, align it to the leading and trailing edge of the superview, and the bottom
	c = [NSLayoutConstraint constraintWithItem:self.content.view
									 attribute:NSLayoutAttributeLeading
									 relatedBy:NSLayoutRelationEqual
										toItem:self.view
									 attribute:NSLayoutAttributeLeading
									multiplier:1.f constant:0];
	c.priority = NSLayoutPriorityDefaultHigh;
	[self.view addConstraint:c];
	
	c = [NSLayoutConstraint constraintWithItem:self.content.view
									 attribute:NSLayoutAttributeTrailing
									 relatedBy:NSLayoutRelationEqual
										toItem:self.view
									 attribute:NSLayoutAttributeTrailing
									multiplier:1.f constant:0];
	c.priority = NSLayoutPriorityDefaultHigh;
	[self.view addConstraint:c];
	
	c = [NSLayoutConstraint constraintWithItem:self.content.view
									 attribute:NSLayoutAttributeBottom
									 relatedBy:NSLayoutRelationEqual
										toItem:self.view
									 attribute:NSLayoutAttributeBottom
									multiplier:1.f constant:0];
	c.priority = NSLayoutPriorityDefaultHigh;
	[self.view addConstraint:c];
	
	// align the top of the content to the bottom of the title bar
	c = [NSLayoutConstraint constraintWithItem:self.content.view
									 attribute:NSLayoutAttributeTop
									 relatedBy:NSLayoutRelationEqual
										toItem:self.titleBar
									 attribute:NSLayoutAttributeBottom
									multiplier:1.f constant:0];
	c.priority = NSLayoutPriorityRequired;
	[self.view addConstraint:c];
}

@end
