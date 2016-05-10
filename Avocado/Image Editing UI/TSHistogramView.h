//
//  TSHistogramView.h
//  Avocado
//
//	Renders an RGB histogram using CALayers.
//
//  Created by Tristan Seifert on 20160510.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSHistogramView : NSView

/// this is the image of which we calculate the histogram
@property (nonatomic) CIImage *image;

/// quality of the histogram, between 1 and 4; Each step causes a downscaling of 1/2.
@property (nonatomic) NSUInteger quality;

@end
