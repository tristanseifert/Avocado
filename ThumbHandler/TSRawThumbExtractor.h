//
//  TSRawThumbExtractor.h
//  Avocado
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const TSRawImageErrorDomain;
extern NSString *const TSRawImageErrorIsFatalKey;

@interface TSRawThumbExtractor : NSObject

/**
 * Initializes the thumb extractor, given the url to the input file. Returns
 * nil if the file could not be loaded.
 */
- (instancetype) initWithRawFile:(NSURL *) url andError:(NSError **) outErr;

/**
 * Extracts a thumbnail of the given size from the raw file. If there are
 * multiple thumbnails present, the largest one, closest to the given size is
 * returned. Otherwise, the existing thumbnail is downscaled (if the size is
 * smaller than its size) or returned as-is.
 */
- (CGImageRef) extractThumbWithSize:(CGFloat) thumbSize;

@end
