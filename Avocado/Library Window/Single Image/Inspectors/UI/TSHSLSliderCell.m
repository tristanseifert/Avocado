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

@interface TSHSLSliderCell ()

/// this is the shader used to draw the slider
@property (nonatomic) CGShadingRef shader;
/// drawing of the track is masked using this image
@property (nonatomic) NSImage *imageMask;

- (void) updateShader;
- (void) updateMaskImageForRect:(NSRect) aRect;

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

#pragma mark Sizing
/**
 * When the cell is resized, invalidate the mask image.
 */
- (void) calcDrawInfo:(NSRect) aRect {
	[super calcDrawInfo:aRect];
	
	self.imageMask = nil;
}

#pragma mark Drawing
/**
 * Performs drawing of the track.
 */
- (void) drawBarInside:(NSRect) aRect flipped:(BOOL) flipped {
	// create a mask image to which drawing the track is masked
	if(self.imageMask == nil ||
	   NSEqualSizes(self.imageMask.size, self.controlView.bounds.size) != YES) {
		[self updateMaskImageForRect:aRect];
	}
	
	CGImageRef maskImage = [self.imageMask CGImageForProposedRect:NULL
														  context:NULL
															hints:nil];
	
	// draw the contents of the track (i.e. the gradient)
	[NSGraphicsContext saveGraphicsState];
	CGContextRef ctx = [NSGraphicsContext currentContext].graphicsPort;
	
	CGContextClipToMask(ctx, self.controlView.bounds, maskImage);
	
	// scale coordinate system (shader needn't be recreated when width changes)
	CGContextScaleCTM(ctx, NSWidth(self.controlView.bounds), 1.f);
	CGContextDrawShading(ctx, self.shader);
	
	[NSGraphicsContext restoreGraphicsState];
}

/**
 * Creates a bezier path that will be filled, given the track rect.
 */
- (NSBezierPath *) pathForTrackRect:(NSRect) rect {
	const CGFloat barRadius = 2.f;
	
	// inset the rect vertically
	NSRect newRect = NSInsetRect(rect, 0, 1.f);
	
	// create path
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:newRect
														 xRadius:barRadius
														 yRadius:barRadius];

	return path;
}

/**
 * Allocates a new shader to use in drawing the gradient.
 */
- (void) updateShader {
	CGColorSpaceRef cs;
	CGFunctionRef shadeFunc;
	
	// is there a previous shader?
	if(self.shader != nil) {
		CGShadingRelease(self.shader);
	}
	
	// create the shader
	CGPoint start = CGPointMake(0.f, 0.5);
	CGPoint end = CGPointMake(1.f, 0.5);
	
	cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	shadeFunc = TSCreateHSLFunction(self.sliderCellType, self.fixedValue);
	self.shader = CGShadingCreateAxial(cs, start, end, shadeFunc, NO, NO);
	
	// deallocate unneeded stuff
	CGColorSpaceRelease(cs);
	CGFunctionRelease(shadeFunc);
}

/**
 * Updates the mask image for the given rect.
 */
- (void) updateMaskImageForRect:(NSRect) aRect {
	self.imageMask = [[NSImage alloc] initWithSize:self.controlView.bounds.size];
	[self.imageMask lockFocus];
	
	[[NSColor colorWithCalibratedWhite:1.f alpha:0.f] setFill];
	NSRectFill(self.controlView.bounds);
	
	[[NSColor blackColor] setFill];
	[[self pathForTrackRect:aRect] fill];
	
	[self.imageMask unlockFocus];
}

#pragma mark Properties
/**
 * Implement the setter for the cell type.
 */
- (void) setSliderCellType:(TSHSLSliderCellType) type {
	_sliderCellType = type;
	
	// update display
	[self updateShader];
	self.imageMask = nil;
	
	[self.controlView setNeedsDisplay:YES];
}

/**
 * Implements the setter for the fixed value.
 */
- (void) setFixedValue:(CGFloat) fixedValue {
	_fixedValue = fixedValue;
	
	// update display
	[self updateShader];
	self.imageMask = nil;
	
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
			hsl[1] = 0.74;
			hsl[2] = 0.5;
			break;
			
		// saturation is interpolated
		case TSHSLSliderCellTypeSaturation:
			hsl[0] = info->centre;
			hsl[1] = MAX(0.05, position);
			hsl[2] = 0.5;
			break;
			
		// lightness is interpolated
		case TSHSLSliderCellTypeLightness:
			hsl[0] = info->centre;
			hsl[1] = 0.74;
			hsl[2] = MAX(0.05, position);
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
