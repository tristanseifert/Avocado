//
//  NSImage+TSCachedDecoding.h
//  Avocado
//
//  Created by Tristan Seifert on 20160530.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (TSCachedDecoding)

/**
 * Forces the receiver to be decoded. This is accomplished by drawing it into
 * a bitmap context, and returning a new image with the output of that context.
 */
- (NSImage *) TSRedrawImageInContext;

/**
 * Forces the image to be decoded.
 */
- (void) TSForceDecoding;

@end
