//
//  TSJPEG2000Parser.h
//  Avocado
//
//  Created by Tristan Seifert on 20160531.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSImage;
@interface TSJPEG2000Parser : NSObject

/**
 * Loads and decodes the full quality JPEG2000 bitstream from the given url, and
 * returns an image with its contents.
 */
+ (NSImage *) jpeg2kFromUrl:(NSURL *) url;

/**
 * Loads and decodes a lower-quality version of the given JPEG2000 bitstream at
 * the given URL. The scale factor can be thought of as the number of times the
 * size is cut in half: 0 is full size, 1 is 1/2, 2 is 1/4, 3 is 1/8, and so
 * forth.
 */
+ (NSImage *) jpeg2kFromUrl:(NSURL *) url withQualityLayer:(NSUInteger) layer;

@end
