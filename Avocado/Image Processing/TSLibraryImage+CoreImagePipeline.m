//
//  TSLibraryImage+CoreImagePipeline.m
//  Avocado
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryImage+CoreImagePipeline.h"
#import "TSHumanModels.h"

#import "TSCoreImagePipelineJob.h"

#import "TSExposureAdjustmentFilter.h"
#import "TSColourControlsFilter.h"
#import "TSVibranceAdjustmentFilter.h"
#import "TSSharpeningAdjustmentFilter.h"
#import "TSNoiseReductionAdjustmentFilter.h"
#import "TSMedianAdjustmentFilter.h"
#import "TSHSLAdjustmentFilter.h"

/// this returns an image adjustment for the given key
#define TSAdjustment(key) \
	((TSLibraryImageAdjustment *) [self.adjustments valueForKey:key])

/// evaluates to the X value of an adjustment, as a double
#define TSAdjustmentXDbl(key) TSAdjustment(key).x.doubleValue
/// evaluates to the Y value of an adjustment, as a double
#define TSAdjustmentYDbl(key) TSAdjustment(key).y.doubleValue
/// evaluates to the Z value of an adjustment, as a double
#define TSAdjustmentZDbl(key) TSAdjustment(key).z.doubleValue
/// evaluates to the W value of an adjustment, as a double
#define TSAdjustmentWDbl(key) TSAdjustment(key).w.doubleValue

/// evaluates to a three component vector, from the X, Y and Z values
#define TSAdjustmentVec3(key) TSAdjustment(key).vector3

@interface TSLibraryImage (CoreImagePipeline_Private)

- (void) TSCISetUpNoiseReduction:(TSCoreImagePipelineJob *) job;
- (void) TSCISetUpSharpening:(TSCoreImagePipelineJob *) job;
- (void) TSCISetUpMedianFilter:(TSCoreImagePipelineJob *) job;

- (void) TSCISetUpExposureAdjustment:(TSCoreImagePipelineJob *) job;
- (void) TSCISetUpColourControls:(TSCoreImagePipelineJob *) job;
- (void) TSCISetUpHSLAdjustment:(TSCoreImagePipelineJob *) job;

@end

@implementation TSLibraryImage (CoreImagePipeline)

/**
 * Sets up the appropriate jobs.
 */
- (void) TSCIPipelineSetUpJob:(TSCoreImagePipelineJob *) job {
	[self TSCISetUpNoiseReduction:job];
	[self TSCISetUpMedianFilter:job];
	[self TSCISetUpSharpening:job];
	
	[self TSCISetUpExposureAdjustment:job];
	[self TSCISetUpHSLAdjustment:job];
	[self TSCISetUpColourControls:job];
}

#pragma mark Sharpening/Noise Reduction
/**
 * Sets up the noise reduction filter.
 */
- (void) TSCISetUpNoiseReduction:(TSCoreImagePipelineJob *) job {
	TSNoiseReductionAdjustmentFilter *filter = [TSNoiseReductionAdjustmentFilter new];
	
	
	// configure filter
	filter.noiseLevel = TSAdjustmentXDbl(TSAdjustmentKeyNoiseReductionLevel);
	filter.sharpening = TSAdjustmentXDbl(TSAdjustmentKeyNoiseReductionSharpness);
	
	// add to job
	[job addFilter:filter];
}

/**
 * Sets up the sharpening filter.
 */
- (void) TSCISetUpSharpening:(TSCoreImagePipelineJob *) job {
	TSSharpeningAdjustmentFilter *filter = [TSSharpeningAdjustmentFilter new];
	
	// configure filter
	filter.lumaSharpening = TSAdjustmentXDbl(TSAdjustmentKeySharpenLuminance);
	
	filter.sharpenRadius = TSAdjustmentXDbl(TSAdjustmentKeySharpenRadius);
	filter.sharpenIntensity = TSAdjustmentXDbl(TSAdjustmentKeySharpenIntensity);
	
	// add to job
	[job addFilter:filter];
}

/**
 * Creates a median filter, if the adjustments call for it, and adds it
 * to the filter chain.
 */
- (void) TSCISetUpMedianFilter:(TSCoreImagePipelineJob *) job {
	BOOL hasMedian = TSAdjustment(TSAdjustmentKeySharpenMedianFilter).x.boolValue;
	
	if(hasMedian) {
		TSMedianAdjustmentFilter *filter = [TSMedianAdjustmentFilter new];
		
		// nothing to configure
		
		[job addFilter:filter];
	}
}

#pragma mark Exposure
/**
 * Sets up the exposure adjustment filter.
 */
- (void) TSCISetUpExposureAdjustment:(TSCoreImagePipelineJob *) job {
	TSExposureAdjustmentFilter *filter = [TSExposureAdjustmentFilter new];
	
	// configure filter
	filter.evAdjustment = TSAdjustmentXDbl(TSAdjustmentKeyExposureEV);
	
	// add to job
	[job addFilter:filter];
}

/**
 * Sets up the colour controls (contrast, etc) filter.
 */
- (void) TSCISetUpColourControls:(TSCoreImagePipelineJob *) job {
	// configure the colour controls filter
	TSColourControlsFilter *filter = [TSColourControlsFilter new];
	
	filter.contrast = TSAdjustmentXDbl(TSAdjustmentKeyToneContrast);
	filter.saturation = TSAdjustmentXDbl(TSAdjustmentKeyToneSaturation);
	filter.brightness = TSAdjustmentXDbl(TSAdjustmentKeyToneBrightness);
	
	[job addFilter:filter];
	
	// configure the vibrance filter
	TSVibranceAdjustmentFilter *filterVibe = [TSVibranceAdjustmentFilter new];
	
	filterVibe.vibrancy = TSAdjustmentXDbl(TSAdjustmentKeyToneVibrance);
	
	[job addFilter:filterVibe];
}

/**
 * Creates a HSL adjustment filter. This converts the X, Y and Z components to
 * vectors, then sets them on the filter.
 */
- (void) TSCISetUpHSLAdjustment:(TSCoreImagePipelineJob *) job {
	TSHSLAdjustmentFilter *filter = [TSHSLAdjustmentFilter new];
	
	filter.inputRedShift = TSAdjustmentVec3(TSAdjustmentKeyColourRed);
	filter.inputOrangeShift = TSAdjustmentVec3(TSAdjustmentKeyColourOrange);
	filter.inputYellowShift = TSAdjustmentVec3(TSAdjustmentKeyColourYellow);
	filter.inputGreenShift = TSAdjustmentVec3(TSAdjustmentKeyColourGreen);
	filter.inputAquaShift = TSAdjustmentVec3(TSAdjustmentKeyColourAqua);
	filter.inputBlueShift = TSAdjustmentVec3(TSAdjustmentKeyColourBlue);
	filter.inputPurpleShift = TSAdjustmentVec3(TSAdjustmentKeyColourPurple);
	filter.inputMagentaShift = TSAdjustmentVec3(TSAdjustmentKeyColourMagenta);
	
	// add filter
	[job addFilter:filter];
}

@end
