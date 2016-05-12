//
//  TSHSLAdjustmentFilter.m
//  Avocado
//
//  Created by Tristan Seifert on 20160512.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

/**
 * The hue values in the shader are calculated as follows:
 *
 * 	DDLogVerbose(@"Red: %f", 0.f);
 * DDLogVerbose(@"Orange: %f", [NSColor colorWithCalibratedRed:0.901961 green:0.584314 blue:0.270588 alpha:1].hue);
 * DDLogVerbose(@"Yellow: %f", [NSColor colorWithCalibratedRed:0.901961 green:0.901961 blue:0.270588 alpha:1].hue);
 * DDLogVerbose(@"Green: %f", [NSColor colorWithCalibratedRed:0.270588 green:0.901961 blue:0.270588 alpha:1].hue);
 * DDLogVerbose(@"Aqua: %f", [NSColor colorWithCalibratedRed:0.270588 green:0.901961 blue:0.901961 alpha:1].hue);
 * DDLogVerbose(@"Blue: %f", [NSColor colorWithCalibratedRed:0.270588 green:0.270588 blue:0.901961 alpha:1].hue);
 * DDLogVerbose(@"Purple: %f", [NSColor colorWithCalibratedRed:0.584314 green:0.270588 blue:0.901961 alpha:1].hue);
 * DDLogVerbose(@"Magenta: %f", [NSColor colorWithCalibratedRed:0.901961 green:0.270588 blue:0.901961 alpha:1].hue);
 */

#import <CoreImage/CoreImage.h>

#import "TSHSLAdjustmentFilter.h"

#import "NSColor+AvocadoUtils.h"

@interface TSHSLAdjustmentFilter ()

@property (nonatomic) NSString *kernelString;
@property (nonatomic) CIColorKernel *kernel;

@end

@implementation TSHSLAdjustmentFilter

/**
 * Initializes the HSL filter.
 */
- (instancetype) init {
	NSError *err = nil;
	
	// init superclass
	if(self = [super init]) {
		// load the kernel from the bundle
		NSBundle *b = [NSBundle mainBundle];
		NSURL *url = [b URLForResource:@"TSHSLAdjustmentFilter"
						 withExtension:@"cikernel"];
		
		self.kernelString = [NSString stringWithContentsOfURL:url
													 encoding:NSUTF8StringEncoding
														error:&err];
		
		if(self.kernelString == nil || err != nil) {
			DDLogError(@"Couldn't load kernel string from %@: %@", url, err);
			return nil;
		}
		
		self.kernel = [CIColorKernel kernelWithString:self.kernelString];
		
		// specify default value for vectors
		self.inputRedShift = [CIVector vectorWithX:0.f Y:1.f Z:1.f];
		self.inputOrangeShift = [CIVector vectorWithX:0.f Y:1.f Z:1.f];
		self.inputYellowShift = [CIVector vectorWithX:0.f Y:1.f Z:1.f];
		self.inputGreenShift = [CIVector vectorWithX:0.f Y:1.f Z:1.f];
		self.inputAquaShift = [CIVector vectorWithX:0.f Y:1.f Z:1.f];
		self.inputBlueShift = [CIVector vectorWithX:0.f Y:1.f Z:1.f];
		self.inputPurpleShift = [CIVector vectorWithX:0.f Y:1.f Z:1.f];
		self.inputMagentaShift = [CIVector vectorWithX:0.f Y:1.f Z:1.f];
	}
	
	return self;
}

/// Category for this filter
- (TSCoreImageFilterCategory) category {
	return TSFilterCategoryColourAdjustment;
}

/**
 * Applies the filter on the specified input image.
 */
- (CIImage *) filterOutput {
	NSArray *args = @[
		// input image
		self.filterInput,
		
		// shift values
		self.inputRedShift,
		self.inputOrangeShift,
		self.inputYellowShift,
		self.inputGreenShift,
		self.inputAquaShift,
		self.inputBlueShift,
		self.inputPurpleShift,
		self.inputMagentaShift
	];
	
	// apply the extent
	return [self.kernel applyWithExtent:self.filterInput.extent
							  arguments:args];
}

@end
