//
//  TSLibraryLightTableCell.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryLightTableCell.h"

@interface TSLibraryLightTableCell ()

@end

@implementation TSLibraryLightTableCell

/**
 * The entire frame is the selection rectangle.
 */
- (NSRect) selectionFrame {
	return self.frame;
}

/**
 * Creates an appropriate CALayer.
 */
- (CALayer *) layerForType:(NSString *) type {
	CALayer *layer = [CALayer layer];
	
	// background
	if([type isEqualToString:IKImageBrowserCellBackgroundLayer]) {
		// it's a solid colour
		layer.backgroundColor = [NSColor darkGrayColor].CGColor;
		
		// add the index number in the top right corner
		CATextLayer *text = [CATextLayer layer];
		text.font = (__bridge CFTypeRef _Nullable)([NSFont monospacedDigitSystemFontOfSize:42 weight:NSFontWeightBold]);
		text.fontSize = 42;
		text.foregroundColor = [NSColor colorWithCalibratedWhite:0.84 alpha:1.0].CGColor;
		
		text.alignmentMode = kCAAlignmentRight;
		
		text.frame = CGRectMake(0, self.frame.size.height - 48, self.frame.size.width, 48);
		
		text.string = @"1234";
		
		[layer addSublayer:text];
	}
	
	return layer;
}

@end
