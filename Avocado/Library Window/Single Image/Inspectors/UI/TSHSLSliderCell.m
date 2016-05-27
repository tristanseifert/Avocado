//
//  TSHSLSliderCell.m
//  Avocado
//
//  Created by Tristan Seifert on 20160526.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSHSLSliderCell.h"

// drawing helpers
static void TSConvertHSLToRGB(float h, float s, float l, float* outR, float* outG, float* outB);
static void TSConvertRGBToHSL(float r, float g, float b, float* outH, float* outS, float* outL);

@interface TSHSLSliderCell ()

- (void) commonInit;

- (NSBezierPath *) pathForTrackRect:(NSRect) rect;

- (void) drawHueVaryingBar:(NSRect) aRect flipped:(BOOL) flipped;

@end

@implementation TSHSLSliderCell

#pragma mark Initializers
- (instancetype) init {
	if(self = [super init]) {
		[self commonInit];
	}
	
	return self;
}

- (instancetype) initWithCoder:(NSCoder *) aDecoder {
	if(self = [super initWithCoder:aDecoder]) {
		[self commonInit];
	}
	
	return self;
}

- (instancetype) initTextCell:(NSString *) aString {
	if(self = [super initTextCell:aString]) {
		[self commonInit];
	}
	
	return self;
}

- (instancetype) initImageCell:(nullable NSImage *) image {
	if(self = [super initImageCell:image]) {
		[self commonInit];
	}
	
	return self;
}

/**
 * Performs common initialization tasks.
 */
- (void) commonInit {
	self.sliderCellType = TSHSLSliderCellTypeHue;
}

#pragma mark Drawing
/**
 * Performs drawing of the track.
 */
- (void) drawBarInside:(NSRect) aRect flipped:(BOOL) flipped {
	// run the proper drawing routine
	switch(self.sliderCellType) {
		case TSHSLSliderCellTypeHue:
			[self drawHueVaryingBar:aRect flipped:flipped];
			break;
			
		default:
			[super drawBarInside:aRect flipped:flipped];
	}
}

/**
 * Creates a bezier path that will be filled, given the track rect.
 */
- (NSBezierPath *) pathForTrackRect:(NSRect) rect {
	const CGFloat barRadius = 2.f;
	
	// inset the rect verticall
	NSRect newRect = NSInsetRect(rect, 0, 1.f);
	
	// create path
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:newRect
														 xRadius:barRadius
														 yRadius:barRadius];

	return path;
}

/**
 * Draws a slider bar with a varying hue.
 */
- (void) drawHueVaryingBar:(NSRect) aRect flipped:(BOOL) flipped {
	NSGradient *grad;
	NSBezierPath *path = [self pathForTrackRect:aRect];
	
	// calculate the colours
	NSColor *leftColour = [NSColor colorWithCalibratedHue:MAX((self.fixedValue - 0.5), 0.f)
											   saturation:1.f
											   brightness:1.f
													alpha:1.f];
	NSColor *centreColour = [NSColor colorWithCalibratedHue:self.fixedValue
												 saturation:1.f
												 brightness:1.f
													  alpha:1.f];
	NSColor *rightColour = [NSColor colorWithCalibratedHue:MIN((self.fixedValue + 0.5), 1.f)
												saturation:1.f
												brightness:1.f
													 alpha:1.f];
	
	// make a gradient
	grad = [[NSGradient alloc] initWithColorsAndLocations:leftColour, 0.f, centreColour, 0.5, rightColour, 1.f, nil];
	[grad drawInBezierPath:path angle:0.f];
}

#pragma mark Properties
/**
 * Implement the setter for the cell type.
 */
- (void) setSliderCellType:(TSHSLSliderCellType) type {
	_sliderCellType = type;
	
	[self.controlView setNeedsDisplay:YES];
}

/**
 * Implements the setter for the fixed value.
 */
- (void) setFixedValue:(CGFloat) fixedValue {
	_fixedValue = fixedValue;
	
	[self.controlView setNeedsDisplay:YES];
}

@end

#pragma mark Helpers
/**
 * Converts an HSL value to a RGB value.
 */
static void TSConvertHSLToRGB(float h, float s, float l, float* outR, float* outG, float* outB) {
	float temp1, temp2;
	float temp[3];
	NSInteger i;
	
	// if saturation = 0, return the luminance value for each, which results in gray.
	if(s == 0.0) {
		*outR = *outG = *outB = l;
		
		return;
	}
	
	// Test luminance, then compute temp values based on luminance and saturation
	if(l < 0.5) {
		temp2 = l * (1.0 + s);
	} else {
		temp2 = l + s - l * s;
	}
	
	temp1 = 2.0 * l - temp2;
	
	// Compute intermediate values based on hue
	temp[0] = h + 1.0 / 3.0;
	temp[1] = h;
	temp[2] = h - 1.0 / 3.0;
	
	for(i = 0; i < 3; ++i) {
		// Adjust the range
		if(temp[i] < 0.0) {
			temp[i] += 1.0;
		} if(temp[i] > 1.0) {
			temp[i] -= 1.0;
		}
		
		if(6.0 * temp[i] < 1.0) {
			temp[i] = temp1 + (temp2 - temp1) * 6.0 * temp[i];
		} else {
			if(2.0 * temp[i] < 1.0) {
				temp[i] = temp2;
			} else {
				if(3.0 * temp[i] < 2.0) {
					temp[i] = temp1 + (temp2 - temp1) * ((2.0 / 3.0) - temp[i]) * 6.0;
				} else {
					temp[i] = temp1;
				}
			}
		}
	}
	
	// output RGB
	*outR = temp[0];
	*outG = temp[1];
	*outB = temp[2];
}

/**
 * Converts a RGB value to an HSL value.
 */
static void TSConvertRGBToHSL(float r, float g, float b, float* outH, float* outS, float* outL) {
	float h, s, l, v, m, vm, r2, g2, b2;
	
	h = s = l = 0;
	
	v = MAX(r, g);
	v = MAX(v, b);
	m = MIN(r, g);
	m = MIN(m, b);
	
	l = (m+v) / 2.0f;
	
	if (l <= 0.0) {
		*outH = h;
		*outS = s;
		*outL = l;
		
		return;
	}
	
	vm = v - m;
	s = vm;
	
	// check if saturation is nonzero
	if (s > 0.0f) {
		s /= (l <= 0.5f) ? (v + m) : (2.0 - v - m);
	} else {
		*outH = h;
		*outS = s;
		*outL = l;
		
		return;
	}
	
	r2 = (v - r) / vm;
	g2 = (v - g) / vm;
	b2 = (v - b) / vm;
	
	if (r == v){
		h = (g == m ? 5.0f + b2 : 1.0f - g2);
	} else if (g == v) {
		h = (b == m ? 1.0f + r2 : 3.0 - b2);
	} else {
		h = (r == m ? 3.0f + g2 : 5.0f - r2);
	}
	
	h /= 6.0f;
	
	// output final HSL values
	*outH = h;
	*outS = s;
	*outL = l;
}
