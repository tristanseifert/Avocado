//
//  TSCoreImageFilter.h
//  Avocado
//
//	This is an abstract-ish superclass for all other filters that the
//	CoreImage pipeline supports. They serve as wrappers around the actual
//	CIFilter objects, and provide a few common methods for dealing with
//	connecting filters together.
//
//  Created by Tristan Seifert on 20160508.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TSCoreImageFilterCategory) {
	TSFilterCategoryNoiseReduceBlur = 1,
	TSFilterCategorySharpening,
	TSFilterCategoryColourAdjustment,
	TSFilterCategoryDistortion,
	TSFilterCategoryGeometry,
	TSFilterCategoryVignetteGrain
};

@class CIImage;
@interface TSCoreImageFilter : NSObject

/// Filter input image
@property (nonatomic) CIImage *filterInput;
/// Filter output image
@property (nonatomic, readonly) CIImage *filterOutput;

/// Filter category; defines when it's executed, relative to other filters.
@property (readonly) TSCoreImageFilterCategory category;

@end
