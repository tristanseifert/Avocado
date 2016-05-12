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

@property (nonatomic) CIFilter *filter;

@end

@implementation TSHSLAdjustmentFilter

/**
 * Initializes the HSL filter.
 */
- (instancetype) init {
	NSError *err = nil;
	
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
	
	// set up filter
	
	// init superclass
	if(self = [super initWithFilter:self.filter]) {
		
	}
	
	return self;
}

@end
