//
//  NSColor+AvocadoUtils.m
//  Avocado
//
//  Created by Tristan Seifert on 20160512.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "NSColor+AvocadoUtils.h"

@implementation NSColor (AvocadoUtils)

/**
 * Returns the hue of the colour.
 */
- (CGFloat) TSGetHue {
	CGFloat hue;
	
	[self getHue:&hue saturation:nil brightness:nil alpha:nil];
	return hue;
}

/**
 * Returns the saturation of the colour.
 */
- (CGFloat) TSGetSaturation {
	CGFloat saturation;
	
	[self getHue:nil saturation:&saturation brightness:nil alpha:nil];
	return saturation;
}

/**
 * Returns the brightness of the colour.
 */
- (CGFloat) TSGetBrightness {
	CGFloat brightness;
	
	[self getHue:nil saturation:nil brightness:&brightness alpha:nil];
	return brightness;
}

@end
