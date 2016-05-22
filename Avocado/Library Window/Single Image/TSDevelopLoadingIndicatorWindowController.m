//
//  TSDevelopLoadingIndicatorWindowController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopLoadingIndicatorWindowController.h"

#import <Quartz/Quartz.h>

// animation duration
static const NSTimeInterval TSAnimationDuration = 0.33f;

@interface TSDevelopLoadingIndicatorWindowController ()

@property (nonatomic) IBOutlet NSVisualEffectView *effectView;

@property (nonatomic) IBOutlet NSTextField *loadingStringView;
@property (nonatomic) IBOutlet NSProgressIndicator *progressIndicator;

- (NSImage *) drawVisualEffectViewMask;

@end

@implementation TSDevelopLoadingIndicatorWindowController

/**
 * Initializes the window controller.
 */
- (instancetype) init {
	if(self = [super initWithWindowNibName:@"TSDevelopLoadingIndicatorWindowController"]) {
		
	}
	
	return self;
}

/**
 * Set up some UI.
 */
- (void) windowDidLoad {
    [super windowDidLoad];
	
	// animate the progress indicator
	[self.progressIndicator startAnimation:self];
	
	// make window transparent
	self.window.opaque = NO;
	self.window.backgroundColor = [NSColor clearColor];
}

/**
 * Draws a mask image for the visual effect view.
 */
- (NSImage *) drawVisualEffectViewMask {
	NSImage *maskImage;
	
	// calculate edge length
	CGFloat cornerRadius = 10.f;
//	CGFloat edgeLength = 2.f * cornerRadius + 1;
	
	// create an image with a drawing block
	maskImage = [NSImage imageWithSize:self.effectView.bounds.size
							   flipped:NO
						drawingHandler:^BOOL (NSRect rect) {
		NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:cornerRadius yRadius:cornerRadius];
									 
		[[NSColor blackColor] setFill];
		[p fill];
		
		// satisfy NSImage
		return YES;
	}];
	
	// set its resizing behaviour
	maskImage.capInsets = NSEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius);
	maskImage.resizingMode = NSImageResizingModeStretch;
	
	return maskImage;
}

/**
 * Shows the window.
 */
- (void) showLoadingWindowInView:(NSView *) view withAnimation:(BOOL) animation {
	// calculate and set
	NSRect frameRelativeToWindow = [view convertRect:view.bounds toView:nil];
	NSRect frameRelativeToScreen = [view.window convertRectToScreen:frameRelativeToWindow];
	
	NSRect windowFrame = {
		.size = {
			.width = 375,
			.height = 64
		},
		
		.origin = frameRelativeToScreen.origin
	};
	
	windowFrame.origin.y += 64;
	windowFrame.origin.x += (NSWidth(frameRelativeToScreen) / 2.f) - (375.f / 2.f);
	
	[self.window setFrame:windowFrame display:YES];
	
	// draw a mask for the visual effect view
	self.effectView.maskImage = [self drawVisualEffectViewMask];
	
	// make the window visible
	if(animation) {
		self.window.alphaValue = 0.f;
		[self.window orderFront:self];
		
		// animate alpha to 1.0
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			context.duration = TSAnimationDuration;
			context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			if(NSApp.currentEvent.modifierFlags & NSShiftKeyMask)
				context.duration = context.duration * 5.f;
			
			
			self.window.animator.alphaValue = 1.f;
		} completionHandler:nil];
	}
	// just order front window
	else {
		[self.window orderFront:self];
	}
}

/**
 * Hides the window.
 */
- (void) hideLoadingWindowWithAnimation:(BOOL) animation {
	// animate alpha to 0.0
	if(animation) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			// set duration and timing function
			context.duration = TSAnimationDuration;
			context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			if(NSApp.currentEvent.modifierFlags & NSShiftKeyMask)
				context.duration = context.duration * 5.f;
			
			// animate alpha to fully transparent
			self.window.animator.alphaValue = 0.f;
		} completionHandler:^{
			[self.window orderOut:self];
		}];
	}
	// just order out window
	else {
		[self.window orderOut:self];
	}
}

@end
