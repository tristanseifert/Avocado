//
//  TSNoiseReductionAdjustmentFilter.m
//  Avocado
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSNoiseReductionAdjustmentFilter.h"

#import <CoreImage/CoreImage.h>

static void *TSInputKVOCtx = &TSInputKVOCtx;
static void *TSUpdateParamsCtx = &TSUpdateParamsCtx;

@interface TSNoiseReductionAdjustmentFilter ()

@property (nonatomic) CIFilter *nrFilter;

@end

@implementation TSNoiseReductionAdjustmentFilter

/**
 * Initializes the noise reduction filter.
 */
- (instancetype) init {
	if(self = [super init]) {
		// create the filter.
		self.nrFilter = [CIFilter filterWithName:@"CINoiseReduction"];
		
		// add KVO
		[self addObserver:self forKeyPath:@"filterInput"
				  options:0 context:TSInputKVOCtx];
		
		[self addObserver:self forKeyPath:@"noiseLevel"
				  options:0 context:TSUpdateParamsCtx];
		[self addObserver:self forKeyPath:@"sharpening"
				  options:0 context:TSUpdateParamsCtx];
	}
	
	return self;
}

/**
 * Removes KVO.
 */
- (void) dealloc {
	@try {
		[self removeObserver:self forKeyPath:@"filterInput"];
	} @catch(NSException* __unused) { }
	
	@try {
		[self removeObserver:self forKeyPath:@"noiseLevel"];
	} @catch(NSException* __unused) { }
	@try {
		[self removeObserver:self forKeyPath:@"sharpening"];
	} @catch(NSException* __unused) { }
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
		[self.nrFilter setValue:self.filterInput
						 forKey:kCIInputImageKey];
	}
	// a filter input changed, so update its parameters
	else if(context == TSUpdateParamsCtx) {
		[self.nrFilter setValue:@(self.noiseLevel)
						 forKey:@"inputNoiseLevel"];
		[self.nrFilter setValue:@(self.sharpening)
						 forKey:kCIInputSharpnessKey];
	}
}

/// Category for this filter
- (TSCoreImageFilterCategory) category {
	return TSFilterCategoryNoiseReduceBlur;
}

/// Returns the filter output
- (CIImage *) filterOutput {
	return [self.nrFilter valueForKey:kCIOutputImageKey];
}

@end
