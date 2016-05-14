//
//  TSInspectorTitleBar.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSInspectorTitleBar.h"

@interface TSInspectorTitleBar ()

/// when set, the selected drawing style is used.
@property (nonatomic) BOOL useSelectedDrawingStyle;

/// tracking area for the cursor update
@property (nonatomic) NSTrackingArea *cursorTrackingArea;

@end

@implementation TSInspectorTitleBar

- (instancetype) initWithFrame:(NSRect) frameRect {
	if(self = [super initWithFrame:frameRect]) {
		self.cursorTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:(NSTrackingInVisibleRect | NSTrackingActiveInKeyWindow | NSTrackingCursorUpdate) owner:self userInfo:nil];
		[self addTrackingArea:self.cursorTrackingArea];
	}
	
	return self;
}

#pragma mark Drawing
/**
 * Draw a vibrant line at the top and at the bottom of the view.
 */
- (void) drawRect:(NSRect) dirtyRect {
    [super drawRect:dirtyRect];
	
	// clear dirtyRect
	[[NSColor clearColor] setFill];
	NSRectFill(dirtyRect);

	// fill the background
	if(self.useSelectedDrawingStyle) {
		[[NSColor colorWithCalibratedWhite:1.f alpha:0.25f] setFill];
	} else {
		[[NSColor colorWithCalibratedWhite:1.f alpha:0.15f] setFill];
	}
	
	NSRect bgRect = self.bounds;
	bgRect.size.height -= 1.f;
	bgRect.origin.y += 1.f;
	
	NSRectFill(bgRect);
	
	// prepare to draw lines
	NSBezierPath *p;
	[[NSColor colorWithCalibratedWhite:1.f alpha:0.10f] setStroke];
	
	// draw bottom line
	p = [NSBezierPath bezierPathWithRect:NSMakeRect(0, -0.5, NSWidth(self.frame), 1)];
	[p stroke];
}

#pragma mark Event Handling
/**
 * When the mouse is down, use the "selected" drawing.
 */
- (void) mouseDown:(NSEvent *) theEvent {
	[super mouseDown:theEvent];
	
	self.useSelectedDrawingStyle = YES;
	[self setNeedsDisplay:YES];
}

/**
 * When the mouse is up, use the normal drawing, and invoke the selector.
 */
- (void) mouseUp:(NSEvent *) theEvent {
	[super mouseUp:theEvent];
	
	[NSApp sendAction:self.action to:self.target from:self];
	
	self.useSelectedDrawingStyle = NO;
	[self setNeedsDisplay:YES];
}

/**
 * Set the cursor to the "hand pointer" cursor.
 */
- (void) cursorUpdate:(NSEvent *) event {
	[[NSCursor pointingHandCursor] set];
}

@end
