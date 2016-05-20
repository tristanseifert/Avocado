//
//  TSMedianAdjustmentFilter.m
//  Avocado
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSMedianAdjustmentFilter.h"

#import <CoreImage/CoreImage.h>

static void *TSInputKVOCtx = &TSInputKVOCtx;

@interface TSMedianAdjustmentFilter ()

@property (nonatomic) CIFilter *medianFilter;

@end

@implementation TSMedianAdjustmentFilter

/**
 * Initializes the exposure adjustment filter.
 */
- (instancetype) init {
	if(self = [super init]) {
		// create the filter.
		self.medianFilter = [CIFilter filterWithName:@"CIMedianFilter"];
		
		// add KVO
		[self addObserver:self forKeyPath:@"filterInput"
				  options:0 context:TSInputKVOCtx];
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
		[self.medianFilter setValue:self.filterInput
							 forKey:kCIInputImageKey];
	}
}

/// Category for this filter
- (TSCoreImageFilterCategory) category {
	return TSFilterCategoryNoiseReduceBlur;
}

/// Returns the filter output
- (CIImage *) filterOutput {
	return [self.medianFilter valueForKey:kCIOutputImageKey];
}

@end
