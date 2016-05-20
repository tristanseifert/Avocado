//
//  TSSharpeningAdjustmentFilter.h
//  Avocado
//
//	Applies two types of sharpening to the image:
//
//	 1. Apply luminance sharpening. The chrominance component of each
//		pixel is left intact.
//	 2. Apply an unsharp mask. Pixels below a threshold have a noise
//		reduction treatment (a local blur) applied, while those above the
//		threshold are sharpened.
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreImageFilter.h"

@interface TSSharpeningAdjustmentFilter : TSCoreImageFilter

/// amount of sharpening to apply in the luminance component [0, 1]
@property (nonatomic) CGFloat lumaSharpening;

/// sharpening radius for unsharp mask [0, 25]
@property (nonatomic) CGFloat sharpenRadius;
/// sharpening intensity [0, 1]
@property (nonatomic) CGFloat sharpenIntensity;

@end
