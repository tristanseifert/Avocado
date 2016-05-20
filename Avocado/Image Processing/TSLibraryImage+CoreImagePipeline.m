//
//  TSLibraryImage+CoreImagePipeline.m
//  Avocado
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryImage+CoreImagePipeline.h"

#import "TSCoreImagePipelineJob.h"

#import "TSExposureAdjustmentFilter.h"
#import "TSSharpeningAdjustmentFilter.h"
#import "TSNoiseReductionAdjustmentFilter.h"
#import "TSMedianAdjustmentFilter.h"
#import "TSHSLAdjustmentFilter.h"

@interface TSLibraryImage (CoreImagePipeline_Private)

- (void) TSCISetUpNoiseReduction:(TSCoreImagePipelineJob *) job;
- (void) TSCISetUpSharpening:(TSCoreImagePipelineJob *) job;
- (void) TSCISetUpMedianFilter:(TSCoreImagePipelineJob *) job;

- (void) TSCISetUpExposureAdjustment:(TSCoreImagePipelineJob *) job;

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
}

#pragma mark Sharpening/Noise Reduction
/**
 * Sets up the noise reduction filter.
 */
- (void) TSCISetUpNoiseReduction:(TSCoreImagePipelineJob *) job {
	TSNoiseReductionAdjustmentFilter *filter = [TSNoiseReductionAdjustmentFilter new];
	
	// configure filter
	NSDictionary *d = self.adjustments[TSAdjustmentKeyDetail];
	
	filter.noiseLevel = [d[TSAdjustmentKeyNoiseReductionLevel] doubleValue];
	filter.sharpening = [d[TSAdjustmentKeyNoiseReductionSharpness] doubleValue];
	
	// add to job
	[job addFilter:filter];
}

/**
 * Sets up the sharpening filter.
 */
- (void) TSCISetUpSharpening:(TSCoreImagePipelineJob *) job {
	TSSharpeningAdjustmentFilter *filter = [TSSharpeningAdjustmentFilter new];
	
	// configure filter
	NSDictionary *d = self.adjustments[TSAdjustmentKeyDetail];
	
	filter.lumaSharpening = [d[TSAdjustmentKeySharpenLuminance] doubleValue];
	
	filter.sharpenRadius = [d[TSAdjustmentKeySharpenRadius] doubleValue];
	filter.sharpenIntensity = [d[TSAdjustmentKeySharpenIntensity] doubleValue];
	
	// add to job
	[job addFilter:filter];
}

/**
 * Creates a median filter, if the adjustments call for it, and adds it
 * to the filter chain.
 */
- (void) TSCISetUpMedianFilter:(TSCoreImagePipelineJob *) job {
	NSDictionary *d = self.adjustments[TSAdjustmentKeyDetail];
	BOOL hasMedian = [d[TSAdjustmentKeySharpenMedianFilter] boolValue];
	
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
	NSDictionary *d = self.adjustments[TSAdjustmentKeyExposure];
	
	filter.evAdjustment = [d[TSAdjustmentKeyExposureEV] doubleValue];
	
	// add to job
	[job addFilter:filter];
}

@end
