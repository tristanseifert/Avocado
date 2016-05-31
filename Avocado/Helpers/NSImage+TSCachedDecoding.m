//
//  NSImage+TSCachedDecoding.m
//  Avocado
//
//  Created by Tristan Seifert on 20160530.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "NSImage+TSCachedDecoding.h"

@implementation NSImage (TSCachedDecoding)

/**
 * Forces the receiver to be decoded. This is accomplished by drawing it into
 * a bitmap context, and returning a new image with the output of that context.
 */
- (NSImage *) TSRedrawImageInContext {
	CGImageRef image = [self CGImageForProposedRect:nil context:nil hints:nil];
	
	// Make a bitmap context of a suitable size to draw to, forcing decode
	NSUInteger width = CGImageGetWidth(image);
	NSUInteger height = CGImageGetHeight(image);
	
	CGColorSpaceRef colourSpace = CGImageGetColorSpace(image);
	CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colourSpace,
											 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
	
	// Draw the image to the context, release it
	CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), image);
	
	// Now get an image ref from the context
	CGImageRef outputImage = CGBitmapContextCreateImage(ctx);
	NSImage *cachedImage = [[NSImage alloc] initWithCGImage:outputImage size:NSZeroSize];
	
	// Clean up
	CGImageRelease(outputImage);
	CGContextRelease(ctx);
	
	return cachedImage;
}

/**
 * Forces the image to be decoded.
 */
- (void) TSForceDecoding {
	CGImageRef image = [self CGImageForProposedRect:nil context:nil hints:nil];
	
	// Make a bitmap context to draw to, to force decoding; but don't do anything with it
	const NSUInteger width = 1;
	const NSUInteger height = 1;
	
	CGColorSpaceRef colourSpace = CGImageGetColorSpace(image);
	CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colourSpace,
											 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
	CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
	CGContextSetAllowsAntialiasing(ctx, NO);
	
	CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), image);
	
	CGContextRelease(ctx);
}

@end
