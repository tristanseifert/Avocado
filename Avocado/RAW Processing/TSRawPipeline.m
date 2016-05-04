//
//  TSRawPipeline.m
//  Avocado
//
//  Created by Tristan Seifert on 20160502.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSRawPipeline.h"
#import "TSPixelFormatConverter.h"
#import "TSRawImage.h"
#import "TSRawPipelineState.h"

#import "TSHumanModels.h"

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#import <Accelerate/Accelerate.h>

@interface TSRawPipeline ()

/// operation queue for RAW processing; a TSRawPipelineJob is queued on it.
@property (nonatomic) NSOperationQueue *queue;

/// raw stage cache; each image's URL + stage is the key
@property (nonatomic) NSCache *rawStageCache;

/// CoreImage context; hardware-accelerated processing for filters
@property (nonatomic) CIContext *ciContext;

// helpers
- (NSBlockOperation *) opDebayer:(TSRawPipelineState *) state;

@end

@implementation TSRawPipeline

/**
 * Initializes the RAW pipeline.
 */
- (instancetype) init {
	if(self = [super init]) {
		// set up operation queue
		self.queue = [NSOperationQueue new];
		
		self.queue.qualityOfService = NSQualityOfServiceUserInitiated;
		self.queue.maxConcurrentOperationCount = 1;
		
		self.queue.name = @"TSRawPipeline";
		
		// set up cache
		self.rawStageCache = [NSCache new];
		
		// set up CoreImage context
		NSDictionary *ciOptions = @{
			// request GPU rendering if possible
			kCIContextUseSoftwareRenderer: @NO,
			// use 128bpp floating point RGBA format
			kCIContextWorkingFormat: @(kCIFormatRGBAf)
		};
		
		self.ciContext = [CIContext contextWithOptions:ciOptions];
		DDAssert(self.ciContext != nil, @"Could not allocate CIContext");
	}
	
	return self;
}

/**
 * Queues the given library image (must be a RAW file) onto the processing
 * queue, with the given callback.
 *
 * @param image Input image; all adjustment objects associated with it are
 * taken into account for processing.
 *
 * @param cache When set, intermediate results of the RAW processing are
 * stored at various steps, so that later adjustments need not cause
 * everything to be recomputed. This should only be used if the user is
 * in the interactive editing mode for that particular image.
 *
 * @param progressCallback This optional callback is invoked every time the
 * pipeline moves on to a later stage.
 *
 * @param outProgress Stores the address of an NSProgress object that tracks
 * the progress of the RAW processing.
 */
- (void) queueRawFile:(nonnull TSLibraryImage *) image
		  shouldCache:(BOOL) cache
   completionCallback:(nonnull TSRawPipelineCompletionCallback) complete
	 progressCallback:(nullable TSRawPipelineProgressCallback) progress
   conversionProgress:(NSProgress * _Nullable * _Nonnull) outProgress {
	// initialize some variables
	NSProgress *convertProgress = nil;
	
	NSBlockOperation *opDebayer, *opDemosaic, *opLensCorrect, *opGamma;
	NSBlockOperation *opRotate, *opConvolute, *opMorpological, *opHisto;
	NSBlockOperation *opCoreImage, *opOutputHistogram, *opDisplayTrans;
	
	TSRawPipelineState *state;
	
	// set up a progress object to track the progress
	convertProgress = [NSProgress progressWithTotalUnitCount:11];
	
	if(outProgress)
		*outProgress = convertProgress;
	
	// create the pipeline state
	state = [TSRawPipelineState new];
	
	state.image = image;
	state.stage = TSRawPipelineStageInitializing;
	state.shouldCache = cache;
	
	// set up the various operations
	opDebayer = [self opDebayer:state];
	
	// set up interdependencies between the operations
	
	// add them to the queue to vamenos the operations
}

#pragma mark - RAW Processing Steps
#pragma mark Interpolation and Lens Corrections
/**
 * Creates the block operation to debayer the RAW data.
 */
- (NSBlockOperation *) opDebayer:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		// debayer the image data
	}];
	
	op.name = @"Debayering";
	return op;
}


@end
