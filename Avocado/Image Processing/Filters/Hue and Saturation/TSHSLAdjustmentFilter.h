//
//  TSHSLAdjustmentFilter.h
//  Avocado
//
//	In the shift values, the X component is the additive hue shift, while
//	the Y and Z are the saturation and lightness multipliers.
//
//  Created by Tristan Seifert on 20160512.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreImageFilter.h"

@class CIVector;
@interface TSHSLAdjustmentFilter : TSCoreImageFilter

/// Adjustments of red components
@property (nonatomic) CIVector *inputRedShift;
/// Adjustments of orange components
@property (nonatomic) CIVector *inputOrangeShift;
/// Adjustments of yellow components
@property (nonatomic) CIVector *inputYellowShift;
/// Adjustments of green components
@property (nonatomic) CIVector *inputGreenShift;
/// Adjustments of aqua components
@property (nonatomic) CIVector *inputAquaShift;
/// Adjustments of blue components
@property (nonatomic) CIVector *inputBlueShift;
/// Adjustments of purple components
@property (nonatomic) CIVector *inputPurpleShift;
/// Adjustments of magenta components
@property (nonatomic) CIVector *inputMagentaShift;

@end
