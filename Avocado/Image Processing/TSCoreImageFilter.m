//
//  TSCoreImageFilter.m
//  Avocado
//
//  Created by Tristan Seifert on 20160508.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreImageFilter.h"

#import <CoreImage/CoreImage.h>

@interface TSCoreImageFilter ()

/// CoreImage filter used internally
@property (nonatomic) CIFilter *filter;

@end

@implementation TSCoreImageFilter

/**
 * Initializes this superclass, and sets the internal filter property to
 * whatever filter has been provided.
 */
- (instancetype) initWithFilter:(CIFilter *) filter {
	if(self = [super init]) {
		self.filter = filter;
	}
	
	return self;
}

#pragma mark Input/Output Images
/**
 * Returns the filter input.
 */
- (CIImage *) filterInput {
	return [self.filter valueForKey:kCIInputImageKey];
}

/**
 * Sets the input of this filter to a CIImage.
 */
- (void) setFilterInput:(CIImage *) filterInput {
	[self.filter setValue:filterInput forKey:kCIInputImageKey];
}

/**
 * Gets a CIImage that represents the output of this filter.
 */
- (CIImage *) filterOutput {
	return [self.filter valueForKey:kCIOutputImageKey];
}

@end
