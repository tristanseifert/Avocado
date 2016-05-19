//
//  TSExposureAdjustmentFilter.m
//  Avocado
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSExposureAdjustmentFilter.h"

#import <CoreImage/CoreImage.h>

static void *TSInputKVOCtx = &TSInputKVOCtx;
static void *TSUpdateParamsCtx = &TSUpdateParamsCtx;

@interface TSExposureAdjustmentFilter ()

/// exposure adjustment filter
@property (nonatomic) CIFilter *expoFilter;

@end

@implementation TSExposureAdjustmentFilter

/**
 * Initializes the exposure adjustment filter.
 */
- (instancetype) init {
	if(self = [super init]) {
		// create the filter.
		self.expoFilter = [CIFilter filterWithName:@"CIExposureAdjust"];
		
		// add KVO
		[self addObserver:self forKeyPath:@"filterInput"
				  options:0 context:TSInputKVOCtx];
		
		[self addObserver:self forKeyPath:@"evAdjustment"
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
		[self.expoFilter setValue:self.filterInput
						   forKey:kCIInputImageKey];
	}
	// a filter input changed, so update its parameters
	else if(context == TSUpdateParamsCtx) {
		[self.expoFilter setValue:@(self.evAdjustment)
						   forKey:kCIInputEVKey];
	}
}

/// Category for this filter
- (TSCoreImageFilterCategory) category {
	return TSFilterCategoryColourAdjustment;
}

/// Returns the filter output
- (CIImage *) filterOutput {
	return [self.expoFilter valueForKey:kCIOutputImageKey];
}

@end
