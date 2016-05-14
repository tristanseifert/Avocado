//
//  TSInspectorTitleBar.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSInspectorTitleBar.h"

@implementation TSInspectorTitleBar

/**
 * Draw a vibrant line at the top and at the bottom of the view.
 */
- (void) drawRect:(NSRect) dirtyRect {
    [super drawRect:dirtyRect];
	
	// clear dirtyRect
	[[NSColor clearColor] setFill];
	NSRectFill(dirtyRect);

	// fill
	[[NSColor colorWithCalibratedWhite:1.f alpha:0.15f] setFill];
	NSRectFill(self.bounds);
	
	// prepare to draw lines
	NSBezierPath *p;
	[[NSColor colorWithCalibratedWhite:1.f alpha:0.10f] setStroke];
	
	// draw bottom line
	p = [NSBezierPath bezierPathWithRect:NSMakeRect(0, -0.5, NSWidth(self.frame), 1)];
	[p stroke];
}

@end
