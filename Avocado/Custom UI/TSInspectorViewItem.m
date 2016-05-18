//
//  TSInspectorViewItem.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TSInspectorViewItem.h"
#import "TSInspectorTitleBar.h"
#import "TSVibrantStackView.h"
#import "TSVibrantView.h"

/// space between the side of the view and the title label
static const CGFloat TSInspectorTitleLabelSpacing = 10.f;

/// duration of the accordion animation, in seconds
static const CGFloat TSInspectorAccordionAnimationDuration = 0.33f;
/// height of the title bar of the inspector, in points
static const CGFloat TSInspectorTitleBarHeight = 25.f;

@interface TSInspectorViewItem ()

@property (nonatomic, strong) NSViewController *content;

// override the view property as a stack view
@property (nonatomic) NSStackView *view;

// layout constraint for the height of the content
@property (nonatomic) NSLayoutConstraint *contentHeightConstraint;

// title bar for the inspector pane
@property (nonatomic) TSInspectorTitleBar *titleBar;
// title label; title is taken from the content view controller
@property (nonatomic) NSTextField *titleLabel;

// whether the content view is expanded or not.
@property (nonatomic, readwrite) BOOL isContentExpanded;

- (void) setUpTitleBar;

- (void) toggleAccordionState:(id) sender;
- (void) setContentVisible:(BOOL) visible withAnimation:(BOOL) animate;

@end

@implementation TSInspectorViewItem
@dynamic view;

/**
 * Sets up an inspector view item, using the given view controller as the
 * content.
 */
+ (instancetype) itemWithContentController:(NSViewController *) content expanded:(BOOL) expanded {
	TSInspectorViewItem *i = [[TSInspectorViewItem alloc] init];
	
	i.content = content;
	i.isContentExpanded = expanded;
	
	// done
	return i;
}

#pragma mark View Handling
/**
 * Sets up a custom view.
 */
- (void) loadView {
	self.view = [[TSVibrantStackView alloc] initWithFrame:NSZeroRect];
	
	self.view.wantsLayer = YES;
	self.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
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
	
	// set up title bar
	[self setUpTitleBar];
	
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
	
	if(self.isContentExpanded == NO) {
		c.constant = 0.f;
	}

	self.contentHeightConstraint = c;
	[self.content.view addConstraint:c];
	
	// now, align it to the leading and trailing edge of the superview, and the bottom
	c = [NSLayoutConstraint constraintWithItem:self.content.view
									 attribute:NSLayoutAttributeLeading
									 relatedBy:NSLayoutRelationEqual
										toItem:self.view
									 attribute:NSLayoutAttributeLeading
									multiplier:1.f constant:10.f];
	c.priority = NSLayoutPriorityDefaultHigh;
	[self.view addConstraint:c];
	
	c = [NSLayoutConstraint constraintWithItem:self.content.view
									 attribute:NSLayoutAttributeTrailing
									 relatedBy:NSLayoutRelationEqual
										toItem:self.view
									 attribute:NSLayoutAttributeTrailing
									multiplier:1.f constant:-10.f];
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

#pragma mark Title Bar
/**
 * Sets up the title bar, and its subviews.
 */
- (void) setUpTitleBar {
	NSLayoutConstraint *c;
	
	// add the title view
	self.titleBar = [[TSInspectorTitleBar alloc] initWithFrame:NSZeroRect];
	self.titleBar.wantsLayer = YES;
	self.titleBar.translatesAutoresizingMaskIntoConstraints = NO;
	
	self.titleBar.target = self;
	self.titleBar.action = @selector(toggleAccordionState:);
	
	[self updateTitleBarTooltip];
	
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
	
	
	// set up title label
	self.titleLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
	self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	
	self.titleLabel.bezeled = NO;
	self.titleLabel.bordered = NO;
	self.titleLabel.drawsBackground = NO;
	self.titleLabel.editable = NO;
	self.titleLabel.selectable = NO;
	
	self.titleLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
	self.titleLabel.textColor = [NSColor labelColor];
	
	// bind its string value to the content controller's title
	self.titleLabel.stringValue = @"Inspector Title";
	[self.titleLabel bind:@"stringValue" toObject:self.content
			  withKeyPath:@"title" options:nil];
	
	[self.titleBar addSubview:self.titleLabel];
	
	// set up constraints for title label
	c = [NSLayoutConstraint constraintWithItem:self.titleLabel
									 attribute:NSLayoutAttributeLeading
									 relatedBy:NSLayoutRelationEqual
										toItem:self.titleBar
									 attribute:NSLayoutAttributeLeading
									multiplier:1.f constant:TSInspectorTitleLabelSpacing];
	c.priority = NSLayoutPriorityRequired;
	[self.titleBar addConstraint:c];
	
	c = [NSLayoutConstraint constraintWithItem:self.titleLabel
									 attribute:NSLayoutAttributeCenterY
									 relatedBy:NSLayoutRelationEqual
										toItem:self.titleBar
									 attribute:NSLayoutAttributeCenterY
									multiplier:1.f constant:-1.f];
	c.priority = NSLayoutPriorityRequired;
	[self.titleBar addConstraint:c];
}

/**
 * Handles toggling of the disclosure triangle.
 */
- (void) toggleAccordionState:(id) sender {
	[self setContentVisible:!self.isContentExpanded withAnimation:YES];
}

/**
 * Updates the tooltip of the title bar.
 */
- (void) updateTitleBarTooltip {
	if(self.isContentExpanded) {
		self.titleBar.toolTip = [NSString stringWithFormat:NSLocalizedString(@"Collapse '%@'", @"accordion expand view tooltip"), self.content.title];
	} else {
		self.titleBar.toolTip = [NSString stringWithFormat:NSLocalizedString(@"Expand '%@'", @"accordion expand view tooltip"), self.content.title];
	}
}

/**
 * Changes the dimensions of the content view, either showing or hiding it. If
 * requested, animation is used.
 */
- (void) setContentVisible:(BOOL) visible withAnimation:(BOOL) animate {
	self.isContentExpanded = visible;
	
	if(animate) {
		// collapse the view
		if(!visible) {
			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				context.duration = TSInspectorAccordionAnimationDuration;
				context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
				
				if(NSApp.currentEvent.modifierFlags & NSShiftKeyMask)
					context.duration = context.duration * 5.f;
				
				self.contentHeightConstraint.animator.constant = 0.f;
				self.content.view.animator.alphaValue = 0.f;
			} completionHandler:^{
				[self updateTitleBarTooltip];
			}];
		}
		// expand the view
		else {
			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				context.duration = TSInspectorAccordionAnimationDuration;
				context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
				
				if(NSApp.currentEvent.modifierFlags & NSShiftKeyMask)
					context.duration = context.duration * 5.f;
				
				self.contentHeightConstraint.animator.constant = self.content.preferredContentSize.height;
				self.content.view.animator.alphaValue = 1.f;
			} completionHandler:^{
				[self updateTitleBarTooltip];
			}];
		}
	}
	// no animation is to be used
	else {
		// collapse the view
		if(!visible) {
			self.contentHeightConstraint.constant = 0.f;
			self.content.view.alphaValue = 0.f;
		}
		// expand the view
		else {
			self.contentHeightConstraint.constant = self.content.preferredContentSize.height;
			self.content.view.alphaValue = 1.f;
		}
		
		// update the tooltip
		[self updateTitleBarTooltip];
	}
}

#pragma mark Properties
/**
 * When the isExpanded property is changed, the size is updated, without any
 * animations.
 */
- (void) setExpanded:(BOOL) expanded {
	self.isContentExpanded = expanded;
	
	[self setContentVisible:expanded withAnimation:NO];
}

/**
 * Returns the expansion state.
 */
- (BOOL) expanded {
	return self.isContentExpanded;
}

+ (NSSet *) keyPathsForValuesAffectingExpanded {
	return [NSSet setWithObject:@"isContentExpanded"];
}

@end