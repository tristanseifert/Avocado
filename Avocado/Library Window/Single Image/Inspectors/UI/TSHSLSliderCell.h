//
//  TSHSLSliderCell.h
//  Avocado
//
//	Custom slider cell that draws the track as a HSL gradient. The value of the
//	slider is interpreted to vary one of the three components.
//
//  Created by Tristan Seifert on 20160526.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * Determines the manner in which the slider cell draws its track contents. The
 * fixed, user-specified value for each of these slider cells is specified in
 * the `fixedValue` property.
 */
typedef NS_ENUM(NSUInteger, TSHSLSliderCellType) {
	/**
	 * Hue is varying, with the center value of the slider being at a specific
	 * value. Both saturation and lightness are fixed at 1. The hue value is
	 * interpolated such that it the max will be hue+1, and the min will be
	 * hue-1.
	 */
	TSHSLSliderCellTypeHue = 1,
	/**
	 * Saturation is varying, while hue is fixed, and lightness is 1. Saturation
	 * is interpreted to be 1 at the center value, and is interpolated to the
	 * min and max points of the slider.
	 */
	TSHSLSliderCellTypeSaturation = 2,
	/**
	 * Lightness is varying, while hue is fixed, and saturation is 1. Lightness
	 * is interpreted to be 1 at the center value, and is interpolated to the
	 * min and max points of the slider.
	 */
	TSHSLSliderCellTypeLightness = 3,
};

IB_DESIGNABLE
@interface TSHSLSliderCell : NSSliderCell

/// slider type
@property (nonatomic) IBInspectable TSHSLSliderCellType sliderCellType;
/// fixed (center) value
@property (nonatomic) IBInspectable CGFloat fixedValue;

@end
