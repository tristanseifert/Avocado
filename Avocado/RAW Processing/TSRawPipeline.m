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
#import "TSPixelFormatConverter.h"

#import "TSRawImageDataHelpers.h"
#import "ahd_interpolate_mod.h"

#import "TSHumanModels.h"

#import "NSBlockOperation+AvocadoUtils.h"

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#import <Accelerate/Accelerate.h>

#define TSAddOperation(operation, state) \
	[state addOperation:operation]; \
	[self.queue addOperation:operation]; \

// TODO: figure out a way to more better expose this from a header?
@interface TSLibraryImage ()
@property (nonatomic, readonly) TSRawImage *libRawHandle;
@end

@interface TSRawPipeline ()

/// operation queue for RAW processing; a TSRawPipelineJob is queued on it.
@property (nonatomic) NSOperationQueue *queue;

/// raw stage cache; each image's URL + stage is the key
@property (nonatomic) NSCache *rawStageCache;
/// pixel format converter
@property (nonatomic) TSPixelConverterRef pixelConverter;

/// internal buffer for the temporary storage of interpolated RGB data
@property (nonatomic) void *interpolatedColourBuf;
/// size (in bytes) of the interpolated colour buffer
@property (nonatomic) size_t interpolatedColourBufSz;

/// CoreImage context; hardware-accelerated processing for filters
@property (nonatomic) CIContext *ciContext;

// helpers
- (NSBlockOperation *) opDebayer:(TSRawPipelineState *) state;
- (NSBlockOperation *) opDemosaic:(TSRawPipelineState *) state;

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
	// debugging info about the file
	DDLogDebug(@"Image size: %@", NSStringFromSize(image.imageSize));
	
	// initialize some variables
	NSProgress *convertProgress = nil;
	
	NSBlockOperation *opDebayer, *opDemosaic, *opLensCorrect, *opGamma;
	NSBlockOperation *opRotate, *opConvolute, *opMorpological, *opHisto;
	NSBlockOperation *opCoreImage, *opOutputHistogram, *opDisplayTrans;
	
	TSRawPipelineState *state;
	
	// figure out whether we can use the existing converter
	if(self.pixelConverter != nil) {
		NSUInteger w, h;
		TSPixelConverterGetSize(self.pixelConverter, &w, &h);
		
		// if size of existing converter is too small, create a new one
		if(w < image.imageSize.width || h < image.imageSize.height) {
			TSPixelConverterResize(self.pixelConverter, image.imageSize.width, image.imageSize.height);
		}
	} else {
		// there is no pixel converter; create one
		self.pixelConverter = TSPixelConverterCreate(NULL, image.imageSize.width, image.imageSize.height);
	}
	
	// allocate the temporary buffer for interpolated colour
	size_t newColourBufSz = (image.imageSize.width * image.imageSize.height) * 4 * sizeof(uint16_t);
	
	if(self.interpolatedColourBuf != nil) {
		// is the buffer large enough?
		if(self.interpolatedColourBufSz < newColourBufSz) {
			// free old buffer
			free(self.interpolatedColourBuf);
			
			// allocate new buffer
			self.interpolatedColourBuf = valloc(newColourBufSz);
			self.interpolatedColourBufSz = newColourBufSz;
			
			DDLogDebug(@"Re-allocated %lu bytes for interpolated colour buffer", self.interpolatedColourBufSz);
		}
	} else {
		self.interpolatedColourBuf = valloc(newColourBufSz);
		self.interpolatedColourBufSz = newColourBufSz;
		
		DDLogDebug(@"Allocated %lu bytes for interpolated colour buffer", self.interpolatedColourBufSz);
	}
	
	// set up a progress object to track the progress
	convertProgress = [NSProgress progressWithTotalUnitCount:11];
	
	if(outProgress)
		*outProgress = convertProgress;
	
	// create the pipeline state
	state = [TSRawPipelineState new];
	
	state.image = image;
	state.stage = TSRawPipelineStageInitializing;
	state.shouldCache = cache;
	
	state.converter = self.pixelConverter;
	
	state.completionCallback = complete;
	state.progressCallback = progress;
	
	state.progress = convertProgress;
	
	state.rawImage = image.libRawHandle;
	state.interpolatedColourBuf = self.interpolatedColourBuf;
	
	// set up the various operations
	opDebayer = [self opDebayer:state];
	opDemosaic = [self opDemosaic:state];
	
	// set up interdependencies between the operations
	[opDemosaic addDependency:opDebayer];
	
	// add them to the queue to vamenos the operations
	TSAddOperation(opDebayer, state);
	TSAddOperation(opDemosaic, state);
}

#pragma mark - RAW Processing Steps
#pragma mark Interpolation and Lens Corrections
/**
 * Creates the block operation to debayer the RAW data. This is accomplished
 * by calling the "unpackRawData" method on the RAW file handle.
 */
- (NSBlockOperation *) opDebayer:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		NSError *err = nil;
		
		state.stage = TSRawPipelineStageDebayering;
		
		// unpack image data
		if([state.rawImage unpackRawData:&err] != YES) {
			DDLogError(@"Error unpacking raw data: %@", err);
			
			[state terminateWithError:err];
			return;
		}
	}];
	
	op.name = @"Debayering";
	return op;
}

/**
 * Decodes the raw Bayer data from the raw file.
 *
 * This involves:
 * 1. Subtracting a dark frame (hot pixel removal)
 * 2. Adjusting the black level
 * 3. Performing interpolation
 * 4. Converting to actual RGB data
 */
- (NSBlockOperation *) opDemosaic:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		state.stage = TSRawPipelineStageDemosaicing;
		
		// copy RAW data into buffer
		libraw_data_t *libRaw = state.rawImage.libRaw;
		
		DDLogDebug(@"Copying data to raw buffer: %p", self.interpolatedColourBuf);
		[state.rawImage copyRawDataToBuffer:self.interpolatedColourBuf];
		DDLogDebug(@"Finished copying data to raw buffer");
		
		// adjust black level
		DDLogVerbose(@"Beginning black level adjustment");
		TSRawAdjustBlackLevel(libRaw, self.interpolatedColourBuf);
		TSRawSubtractBlack(libRaw, self.interpolatedColourBuf);
		DDLogVerbose(@"Completed black level adjustment");
		
		
		// white balance (colour scaling) and pre-interpolation
		state.stage = TSRawPipelineStageWhiteBalance;
		
		TSRawPreInterpolationApplyWB(libRaw, self.interpolatedColourBuf);
		TSRawPreInterpolation(libRaw, self.interpolatedColourBuf);
		
		
		// interpolate colour data
		state.stage = TSRawPipelineStageInterpolateColour;
		
		DDLogVerbose(@"Beginning colour interpolation (c = %i)", libRaw->idata.colors);
		ahd_interpolate_mod(libRaw, self.interpolatedColourBuf);
		DDLogVerbose(@"Completed colour interpolation");
		
		
		// convert to RGB
		state.stage = TSRawPipelineStageConvertToRGB;
		
		DDLogVerbose(@"Beginning RGB conversion");
		void *outBuf = TSPixelConverterGetRGBXPointer(state.converter);
		TSRawConvertToRGB(libRaw, self.interpolatedColourBuf, outBuf);
		DDLogVerbose(@"Completed RGB conversion");
		
		
		// save buffer to disk (debug testing)
		NSFileManager *fm = [NSFileManager defaultManager];
		NSURL *appSupportURL = [[fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
		appSupportURL = [appSupportURL URLByAppendingPathComponent:@"me.tseifert.Avocado"];
		
		NSData *rawData = [NSData dataWithBytesNoCopy:outBuf length:(state.rawImage.size.width * 3 * 2) * state.rawImage.size.height freeWhenDone:NO];
		[rawData writeToURL:[appSupportURL URLByAppendingPathComponent:@"test_raw_data.raw"] atomically:NO];
		
		DDLogVerbose(@"Finished writing debug data");
	}];
	
	op.name = @"Demosaicing";
	return op;
}

@end
