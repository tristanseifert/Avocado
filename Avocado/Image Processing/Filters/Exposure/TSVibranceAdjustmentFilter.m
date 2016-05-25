//
//  TSVibranceAdjustmentFilter.m
//  Avocado
//
//  Created by Tristan Seifert on 20160525.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSVibranceAdjustmentFilter.h"

#import <CoreImage/CoreImage.h>

static void *TSInputKVOCtx = &TSInputKVOCtx;
static void *TSUpdateParamsCtx = &TSUpdateParamsCtx;

@interface TSVibranceAdjustmentFilter ()

@property (nonatomic) CIFilter *colourCtrlFilter;

@end

@implementation TSVibranceAdjustmentFilter

/**
 * Initializes the exposure adjustment filter.
 */
- (instancetype) init {
	if(self = [super init]) {
		// create the filter.
		self.colourCtrlFilter = [CIFilter filterWithName:@"CIVibrance"];
		
		// add KVO
		[self addObserver:self forKeyPath:@"filterInput"
				  options:0 context:TSInputKVOCtx];
		
		[self addObserver:self forKeyPath:@"vibrancy"
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
		[self removeObserver:self forKeyPath:@"vibrancy"];
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
		[self.colourCtrlFilter setValue:self.filterInput
								 forKey:kCIInputImageKey];
	}
	// a filter input changed, so update its parameters
	else if(context == TSUpdateParamsCtx) {
		[self.colourCtrlFilter setValue:@(self.vibrancy)
								 forKey:@"inputAmount"];
	}
}

/// Category for this filter
- (TSCoreImageFilterCategory) category {
	return TSFilterCategoryColourAdjustment;
}

/// Returns the filter output
- (CIImage *) filterOutput {
	return [self.colourCtrlFilter valueForKey:kCIOutputImageKey];
}

@end
