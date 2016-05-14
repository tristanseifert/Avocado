//
//  TSHistogramView.h
//  Avocado
//
//	Mr. Histogram renders an YRGB (luma + RGB) histogram using the magic of
//	CALayers, with some slick animations to boot. Set the image, quality,
//	and a lovely histogram results. That's it. Mr. Histogram is great.
//
//  Created by Tristan Seifert on 20160510.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSHistogramView : NSView

/// This is the image of which we calculate the histogram
@property (nonatomic, strong) NSImage *image;

/// Quality of the histogram, between 1 and 4; Each step causes a size reduction of 1/2.
@property (nonatomic) NSUInteger quality;

/**
 * Forces the view's histogram to be redrawn.
 */
- (void) redrawHistogram;

@end
