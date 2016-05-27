//
//  TSHSLSliderCell.m
//  Avocado
//
//  Created by Tristan Seifert on 20160526.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSHSLSliderCell.h"
#import "NSBezierPath+AvocadoUtils.h"

#import <CoreGraphics/CoreGraphics.h>

typedef struct {
	TSHSLSliderCellType type;
	CGFloat centre;
} TSGradientInfo;

// drawing helpers
static CGFunctionRef TSCreateHSLFunction(TSHSLSliderCellType type, CGFloat centre);
static void TSHSLInterpolateFunc(void *inInfo, const CGFloat *in, CGFloat *out);

static void TSConvertHSLToRGB(CGFloat h, CGFloat s, CGFloat l, CGFloat* outR, CGFloat* outG, CGFloat* outB);
static void TSConvertRGBToHSL(CGFloat r, CGFloat g, CGFloat b, CGFloat* outH, CGFloat* outS, CGFloat* outL);

@interface TSHSLSliderCell ()

- (void) commonInit;

- (NSBezierPath *) pathForTrackRect:(NSRect) rect;

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
	CGColorSpaceRef cs;
	CGFunctionRef shadeFunc;
	CGShadingRef shade;
	
	// create a mask image to which the thingie is masked
	NSImage *mask = [[NSImage alloc] initWithSize:self.controlView.bounds.size];
	[mask lockFocus];
	
	[[NSColor colorWithCalibratedWhite:1.f alpha:0.f] setFill];
	NSRectFill(self.controlView.bounds);
	
	[[NSColor blackColor] setFill];
	[[self pathForTrackRect:aRect] fill];
	
	[mask unlockFocus];
	
	CGImageRef maskImage = [mask CGImageForProposedRect:NULL context:NULL hints:nil];
	
	
	// create the shading object
	CGPoint start = CGPointMake(0.f, 0.5);
	CGPoint end = CGPointMake(NSWidth(aRect), 0.5);
	
	cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	shadeFunc = TSCreateHSLFunction(self.sliderCellType, self.fixedValue);
	shade = CGShadingCreateAxial(cs, start, end, shadeFunc, NO, NO);
	
	
	// get a copy of the graphics context and save state
	[NSGraphicsContext saveGraphicsState];
	CGContextRef ctx = [NSGraphicsContext currentContext].graphicsPort;
	
	// clip to the previously generated mask image, then draw
	CGContextClipToMask(ctx, self.controlView.bounds, maskImage);
	CGContextDrawShading(ctx, shade);
	
	// clean up
	[NSGraphicsContext restoreGraphicsState];
	
	CGColorSpaceRelease(cs);
	CGFunctionRelease(shadeFunc);
	CGShadingRelease(shade);
}

/**
 * Creates a bezier path that will be filled, given the track rect.
 */
- (NSBezierPath *) pathForTrackRect:(NSRect) rect {
	const CGFloat barRadius = 2.f;
	
	// inset the rect verticall
	NSRect newRect = NSInsetRect(rect, 0, 1.f);
	newRect.size.width -= 1.f;
	
	// create path
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:newRect
														 xRadius:barRadius
														 yRadius:barRadius];

	return path;
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

#pragma mark HSL Gradient Drawing
/**
 * Creates a CGFunction that is used for shading.
 */
static CGFunctionRef TSCreateHSLFunction(TSHSLSliderCellType type, CGFloat centre) {
	// allocate a struct with drawing info
	TSGradientInfo *info = malloc(sizeof(TSGradientInfo));
	info->type = type;
	info->centre = centre;
	
	// get colour space
	CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	
	// actually make the function
	size_t numComponents;
	const CGFloat inRange[2] = { 0, 1 };
	const CGFloat outRange[8] = { 0, 1, 0, 1, 0, 1, 0, 1 };
	const CGFunctionCallbacks callbacks = { 0,
		&TSHSLInterpolateFunc,
		&free
	};
	
	numComponents = 1 + CGColorSpaceGetNumberOfComponents(cs);
	
	return CGFunctionCreate(info, 1, inRange, numComponents, outRange,
							&callbacks);
}

/**
 * HSL gradient interpolation function
 */
static void TSHSLInterpolateFunc(void *inInfo, const CGFloat *in, CGFloat *out) {
	// get the input position and data
	CGFloat position = in[0];
	TSGradientInfo *info = (TSGradientInfo *) inInfo;
	
	// HSL colour
	CGFloat hsl[3];
	
	CGFloat add = ((position * 2.f) - 1.f) / 2.f;
	
	// determine how to interpolate
	switch (info->type) {
		// hue is interpolated
		case TSHSLSliderCellTypeHue:
			hsl[0] = (info->centre + (add / 2.f));
			hsl[1] = 0.66;
			hsl[2] = 0.5;
			break;
			
		// saturation is interpolated
		case TSHSLSliderCellTypeSaturation:
			hsl[0] = info->centre;
			hsl[1] = position;
			hsl[2] = 0.5;
			break;
			
		// lightness is interpolated
		case TSHSLSliderCellTypeLightness:
			hsl[0] = info->centre;
			hsl[1] = 0.66;
			hsl[2] = position;
			break;
			
		default:
			break;
	}
	
	// convert HSL to RGB and output
	TSConvertHSLToRGB(hsl[0], hsl[1], hsl[2], &out[0], &out[1], &out[2]);
	out[3] = 0.85;
}

#pragma mark Helpers
/**
 * Converts an HSL value to a RGB value.
 */
static void TSConvertHSLToRGB(CGFloat h, CGFloat s, CGFloat l, CGFloat* outR, CGFloat* outG, CGFloat* outB) {
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
static void TSConvertRGBToHSL(CGFloat r, CGFloat g, CGFloat b, CGFloat* outH, CGFloat* outS, CGFloat* outL) {
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
