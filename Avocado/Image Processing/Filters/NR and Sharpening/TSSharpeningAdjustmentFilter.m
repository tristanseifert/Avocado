//
//  TSSharpeningAdjustmentFilter.m
//  Avocado
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSSharpeningAdjustmentFilter.h"

#import <CoreImage/CoreImage.h>

static void *TSInputKVOCtx = &TSInputKVOCtx;
static void *TSUpdateParamsCtx = &TSUpdateParamsCtx;

@interface TSSharpeningAdjustmentFilter ()

@property (nonatomic) CIFilter *sharpenLuma;
@property (nonatomic) CIFilter *unsharpMask;

@end

@implementation TSSharpeningAdjustmentFilter

/**
 * Initializes the exposure adjustment filter.
 */
- (instancetype) init {
	if(self = [super init]) {
		// create the filters.
		self.sharpenLuma = [CIFilter filterWithName:@"CISharpenLuminance"];
		self.unsharpMask = [CIFilter filterWithName:@"CIUnsharpMask"];
		
		// add KVO
		[self addObserver:self forKeyPath:@"filterInput"
				  options:0 context:TSInputKVOCtx];
		
		[self addObserver:self forKeyPath:@"lumaSharpening"
				  options:0 context:TSUpdateParamsCtx];
		[self addObserver:self forKeyPath:@"sharpenRadius"
				  options:0 context:TSUpdateParamsCtx];
		[self addObserver:self forKeyPath:@"sharpIntensity"
				  options:0 context:TSUpdateParamsCtx];
	}
	
	return self;
}

/**
 * Updates the filter's input, as well as its parameters, when they are
 * changed.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	// input image changed
	if(context == TSInputKVOCtx) {
		[self.sharpenLuma setValue:self.filterInput
							forKey:kCIInputImageKey];
		[self.unsharpMask setValue:self.sharpenLuma.outputImage
							forKey:kCIInputImageKey];
	}
	// a filter input changed, so update its parameters
	else if(context == TSUpdateParamsCtx) {
		[self.sharpenLuma setValue:@(self.lumaSharpening)
							forKey:kCIInputSharpnessKey];
		
		[self.unsharpMask setValue:@(self.sharpenRadius)
							forKey:kCIInputRadiusKey];
		[self.unsharpMask setValue:@(self.sharpIntensity)
							forKey:kCIInputIntensityKey];
	}
}

/// Category for this filter
- (TSCoreImageFilterCategory) category {
	return TSFilterCategorySharpening;
}

/// Returns the filter output
- (CIImage *) filterOutput {
	return [self.unsharpMask valueForKey:kCIOutputImageKey];
}

@end
