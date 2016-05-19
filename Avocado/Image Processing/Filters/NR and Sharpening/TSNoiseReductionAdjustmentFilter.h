//
//  TSNoiseReductionAdjustmentFilter.h
//  Avocado
//
//	Runs a noise reduction algorithm on the image. Small changes in
//	luminance below a certain level are blurred, while any pixels
//	above this are sharpened.
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreImageFilter.h"

@interface TSNoiseReductionAdjustmentFilter : TSCoreImageFilter

/// input noise level; [0, 1]
@property (nonatomic) CGFloat noiseLevel;
/// amount of sharpening to apply to edges
@property (nonatomic) CGFloat sharpening;

@end
