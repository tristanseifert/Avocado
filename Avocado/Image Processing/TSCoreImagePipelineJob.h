//
//  TSCoreImagePipelineJob.h
//  Avocado
//
//	The CoreImage pipeline operates synchronously on job objects, which
//	encapsulate all information needed to transform the input image, such
//	as filters and their properties, output image format, and so forth.
//
//  Created by Tristan Seifert on 20160508.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CIImage;
@class TSCoreImageFilter;
@interface TSCoreImagePipelineJob : NSObject

/**
 * Initializes the pipeline job, with the given input image.
 */
- (instancetype) initWithInput:(CIImage *) input;

/**
 * Adds a filter to the pipeline job. It will be placed at the END of its
 * respective filter set.
 */
- (void) addFilter:(TSCoreImageFilter *) filter;

/**
 * Prepares the job for rendering. This will connect the first filter's
 * input to the input image, its output to the next filter, and so forth,
 * until the last filter is reached, whose output is placed in the
 * `result` variable.
 */
- (void) prepareForRendering;

/// input image for the job
@property (nonatomic) CIImage *input;
/// final output image of the job; this will be rendered.
@property (nonatomic) CIImage *result;

@end
