//
//  TSCoreImagePipelineJob.m
//  Avocado
//
//  Created by Tristan Seifert on 20160508.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreImagePipelineJob.h"
#import "TSCoreImageFilter.h"

#import <CoreImage/CoreImage.h>

@interface TSCoreImagePipelineJob ()

/// set containing noise reduction and blur filters (1st)
@property (nonatomic) NSMutableOrderedSet<TSCoreImageFilter *> *filtersNRBlur;
/// set containing sharpening filters (2nd)
@property (nonatomic) NSMutableOrderedSet<TSCoreImageFilter *> *filtersSharpening;
/// set containing colour adjustments/effects filters (3rd)
@property (nonatomic) NSMutableOrderedSet<TSCoreImageFilter *> *filterColourAdjust;
/// set containing distortion filters (4rd)
@property (nonatomic) NSMutableOrderedSet<TSCoreImageFilter *> *filterDistortion;
/// set containing geometry adjustment filters (5rd)
@property (nonatomic) NSMutableOrderedSet<TSCoreImageFilter *> *filterGeometry;
/// set containing vignette/grain filters (6rd)
@property (nonatomic) NSMutableOrderedSet<TSCoreImageFilter *> *filterVignetteGrain;


- (void) connectInputOfFilter:(TSCoreImageFilter *) input toFilterOutput:(TSCoreImageFilter *) output;

@end

@implementation TSCoreImagePipelineJob

/**
 * Initializes the pipeline job's internal data structures.
 */
- (instancetype) init {
	if(self = [super init]) {
		self.filtersNRBlur = [NSMutableOrderedSet new];
		self.filtersSharpening = [NSMutableOrderedSet new];
		self.filterColourAdjust = [NSMutableOrderedSet new];
		self.filterDistortion = [NSMutableOrderedSet new];
		self.filterGeometry = [NSMutableOrderedSet new];
		self.filterVignetteGrain = [NSMutableOrderedSet new];
	}
	
	return self;
}

/**
 * Initializes the pipeline job, with the given input image.
 */
- (instancetype) initWithInput:(CIImage *) input {
	if(self = [self init]) {
		self.input = self.result = input;
	}
	
	return self;
}

#pragma mark Filter Handling
/**
 * Adds a filter to the pipeline job. It will be placed at the END of its
 * respective filter set.
 */
- (void) addFilter:(TSCoreImageFilter *) filter {
	switch (filter.category) {
		// noise reduction and blurs
		case TSFilterCategoryNoiseReduceBlur:
			[self.filtersNRBlur addObject:filter];
			break;
			
		// Sharpening
		case TSFilterCategorySharpening:
			[self.filtersSharpening addObject:filter];
			break;
			
		// Colour adjustment
		case TSFilterCategoryColourAdjustment:
			[self.filterColourAdjust addObject:filter];
			break;
			
		// Distortion
		case TSFilterCategoryDistortion:
			[self.filterDistortion addObject:filter];
			break;
			
		// Geometry adjustments
		case TSFilterCategoryGeometry:
			[self.filterGeometry addObject:filter];
			break;
			
		// Vignetting and grain
		case TSFilterCategoryVignetteGrain:
			[self.filterVignetteGrain addObject:filter];
			break;
	}
}

#pragma mark Filter Connections

/**
 * Prepares the job for rendering. This will connect the first filter's
 * input to the input image, its output to the next filter, and so forth,
 * until the last filter is reached, whose output is placed in the
 * `result` variable.
 */
- (void) prepareForRendering {
	__block TSCoreImageFilter *lastFilter = nil;
	
	// iterate over each of the sets with the same block
	void (^setIterator)(TSCoreImageFilter*, NSUInteger, BOOL*) = ^(TSCoreImageFilter *filter, NSUInteger idx, BOOL *stop) {
		// if we had a previous filter, connect its output to this input
		if(lastFilter != nil) {
			[self connectInputOfFilter:filter toFilterOutput:lastFilter];
		}
		// connect its input to the input image
		else {
			filter.filterInput = self.input;
		}
		
		// store the filter for next iteration
		lastFilter = filter;
	};

	[self.filtersNRBlur enumerateObjectsUsingBlock:setIterator];
	[self.filtersSharpening enumerateObjectsUsingBlock:setIterator];
	[self.filterColourAdjust enumerateObjectsUsingBlock:setIterator];
	[self.filterDistortion enumerateObjectsUsingBlock:setIterator];
	[self.filterGeometry enumerateObjectsUsingBlock:setIterator];
	[self.filterVignetteGrain enumerateObjectsUsingBlock:setIterator];
	
	// store the last filter's output
	self.result = lastFilter.filterOutput;
	
	// if there are no filters, log a warning message
	if(lastFilter == nil) {
		DDLogWarn(@"No filters in %@; this will cause undefined behavior when rendering", self);
		
		// for testing, if there really are no filters
		self.result = self.input;
	}
}

/**
 * Connects the input of the given filter to the output of yet another
 * filter.
 *
 * @param input Input filter, whose input to change.
 * @param output Filter whose output to connect to the filter's input.
 */
- (void) connectInputOfFilter:(TSCoreImageFilter *) input toFilterOutput:(TSCoreImageFilter *) output {
	input.filterInput = output.filterOutput;
}

@end
