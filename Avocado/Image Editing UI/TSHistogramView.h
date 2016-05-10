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

@end
