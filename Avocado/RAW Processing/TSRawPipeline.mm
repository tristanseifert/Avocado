//
//  TSRawPipeline.m
//  Avocado
//
//  Created by Tristan Seifert on 20160502.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSRawPipeline.h"
#import "TSCoreImagePipeline.h"
#import "TSRawImage.h"
#import "TSRawPipelineState.h"
#import "TSRawCache.h"

#import "TSPixelFormatConverter.h"
#import "TSRawImageDataHelpers.h"

#import "ahd_interpolate_mod.h"
#import "lmmse_interpolate.h"

#import "TSCoreDataStore.h"
#import "TSHumanModels.h"

#import "TSLibraryImage+CoreImagePipeline.h"

#import "NSColorSpace+ExtraColourSpaces.h"

#import "TSGroupContainerHelper.h"

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#import <Accelerate/Accelerate.h>

/**
 * When set to a non-zero value, information about the time taken for each of
 * the RAW processing steps is printed.
 */
#define	TSWriteStepTiming	1

/**
 * Set this define to 1 to write debug data from the various stages of the
 * pipeline to disk.
 */
#define	WriteDebugData		0

#define TSAddOperation(operation, state) \
	[state addOperation:operation]; \
	[self.queue addOperation:operation];

#if TSWriteStepTiming
	#define TSBeginOperation(name) \
		time_t __tBegin = clock(); \
		NSString *__opName = name;

	#define TSEndOperation() \
		DDLogDebug(@"Finished %@: %fs", __opName, ((double)(clock() - __tBegin)) / CLOCKS_PER_SEC);
#else
	#define TSBeginOperation(name)
	#define TSEndOperation()
#endif

// TODO: figure out a way to more better expose this from a header?
@interface TSLibraryImage ()
@property (nonatomic, readonly) TSRawImage *libRawHandle;
@end

@interface TSRawPipeline ()

/// operation queue for RAW processing; a TSRawPipelineJob is queued on it.
@property (nonatomic) NSOperationQueue *queue;

/// pixel format converter
@property (nonatomic) TSPixelConverterRef pixelConverter;

/// internal buffer for the temporary storage of interpolated RGB data
@property (nonatomic) void *interpolatedColourBuf;
/// size (in bytes) of the interpolated colour buffer
@property (nonatomic) size_t interpolatedColourBufSz;

/// CoreImage pipeline
@property (nonatomic) TSCoreImagePipeline *ciPipeline;

// helpers
- (NSBlockOperation *) opDebayer:(TSRawPipelineState *) state;
- (NSBlockOperation *) opDemosaic:(TSRawPipelineState *) state;

- (NSBlockOperation *) opLensCorrect:(TSRawPipelineState *) state;
- (NSBlockOperation *) opGammaColourSpaceCorrect:(TSRawPipelineState *) state;

- (NSBlockOperation *) opConvertToPlanar:(TSRawPipelineState *) state;

- (NSBlockOperation *) opRotateFlip:(TSRawPipelineState *) state;
- (NSBlockOperation *) opConvolve:(TSRawPipelineState *) state;
- (NSBlockOperation *) opMorphological:(TSRawPipelineState *) state;
- (NSBlockOperation *) opHistogramAdjust:(TSRawPipelineState *) state;

- (NSBlockOperation *) opConvertToInterleaved:(TSRawPipelineState *) state;

- (NSBlockOperation *) opCoreImageFilters:(TSRawPipelineState *) state;

// conversion
- (CIImage *) ciImageFromPixelConverter:(TSPixelConverterRef) converter andSize:(NSSize) outputSize;

// caching
/// cache handler
@property (nonatomic) TSRawCache *cache;

- (void) beginFullPipelineRunWithState:(TSRawPipelineState *) state shouldCacheResults:(BOOL) cache;
- (void) resumePipelineRunWithCachedData:(TSRawPipelineState *) state shouldCacheResults:(BOOL) cache;

- (void) storeFloatDataCached:(TSRawPipelineState *) state;
- (void) restoreFloatDataCached:(TSRawPipelineState *) state;

- (void) restoreHalfSizeFloatDataCached:(TSRawPipelineState *) state;

- (NSBlockOperation *) opStorePlanarInCache:(TSRawPipelineState *) state;
- (NSBlockOperation *) opRestorePlanarFromCache:(TSRawPipelineState *) state;

// housekeeping
- (NSBlockOperation *) opCleanUp:(TSRawPipelineState *) state;
- (void) cleanUpState:(TSRawPipelineState *) state;

// debugging
- (void) dumpImageBufferInterleaved:(TSRawPipelineState *) state;
- (void) dumpImageBufferCoreImage:(TSRawPipelineState *) state;

@end

@implementation TSRawPipeline

#pragma mark - Initialization
/**
 * Initializes the RAW pipeline.
 */
- (instancetype) init {
	if(self = [super init]) {
		// Set up operation queue
		self.queue = [NSOperationQueue new];
		
		self.queue.qualityOfService = NSQualityOfServiceUserInitiated;
		self.queue.maxConcurrentOperationCount = 1;
		
		self.queue.name = @"TSRawPipeline";
		
		// Create CoreImage pipeline
		self.ciPipeline = [TSCoreImagePipeline new];
		
		// Create the cache
		self.cache = [TSRawCache new];
	}
	
	return self;
}

/**
 * Cleans up various buffers.
 */
- (void) dealloc {
	// clear allocated memory
	TSPixelConverterFree(self.pixelConverter);
	free(self.interpolatedColourBuf);
}

#pragma mark Job Submission
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
 * @param intent Final rendering intent of the image; i.e. what the image will
 * be used for. This gives the pipeline hints to change the way the image is
 * processed, balancing speed and quality for the given use case. Note that
 * some intents may produce images smaller than the full image.
 *
 * @param outFormat Output format of the image; since the final pass of the
 * pipeline involves using CoreImage on the GPU, it is much faster to instead
 * render the image into a GPU texture, and use a bit of Metal magic to render
 * it in a view. If the image should be written to a file, it is of course
 * necessary to copy the image to the CPU, in which case an NSImage will be
 * produced.
 *
 * @param progressCallback This optional callback is invoked every time the
 * pipeline moves on to a later stage.
 *
 * @param outProgress Stores the address of an NSProgress object that tracks
 * the progress of the RAW processing.
 */
- (void) queueRawFile:(nonnull TSLibraryImage *) image
		  shouldCache:(BOOL) cache
	  renderingIntent:(TSRawPipelineIntent) intent
		 outputFormat:(TSRawPipelineOutputFormat) outFormat
   completionCallback:(nonnull TSRawPipelineCompletionCallback) complete
	 progressCallback:(nullable TSRawPipelineProgressCallback) progress
   conversionProgress:(NSProgress * _Nonnull * _Nullable) outProgress {
	// debugging info about the file
	DDLogDebug(@"Image size: %@", NSStringFromSize(image.imageSize));
	
	// initialize some variables
	TSRawPipelineState *state;
	
	// reset file
	if([image.libRawHandle recycle] != YES) {
		DDLogWarn(@"Couldn't recycle raw file: this might cause issues later on, but continuing anyways.");
	}
	
	// figure out whether we can use the existing converter
	if(self.pixelConverter != nil) {
		NSUInteger w, h;
		TSPixelConverterGetSize(self.pixelConverter, &w, &h);
		
		// resize if the size isn't identical
		if(w != image.imageSize.width || h != image.imageSize.height) {
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
	
	// create the pipeline state
	state = [TSRawPipelineState new];
	
	state.stage = TSRawPipelineStageInitializing;
	state.shouldCache = cache;
	
	state.intent = intent;
	state.outFormat = outFormat;
	
	state.converter = self.pixelConverter;
	
	state.completionCallback = complete;
	state.progressCallback = progress;
	
	state.interpolatedColourBuf = self.interpolatedColourBuf;
	
	state.histogramBuf = (int *) valloc(sizeof(int) * 4 * 0x2000);
	state.gammaCurveBuf = (uint16_t *) valloc(sizeof(uint16_t) * 0x10000);
	
	state.applyLensCorrections = NO;
	state.lcLens = nil;
	state.lcModifier = nil;
	
	// Create a temporary managed object context
	NSString *name = [NSString stringWithFormat:@"%@//%@//Image %p", [self className], self, image];
	state.mocCtx = [TSCoreDataStore temporaryWorkerContextWithName:name];
	
	state.image = [image TSInContext:state.mocCtx];
	
	// get some data out of the image data
	[state.mocCtx performBlockAndWait:^{
		state.imageUuid = state.image.uuid;
		state.rawImage = state.image.libRawHandle;
		
		state.outputSize = state.rawImage.size;
		state.rawSize = state.image.imageSize;
	}];
	
	// check if we can resume the processing operation
	if(cache && [self.cache hasDataForUuid:state.imageUuid] == YES) {
		DDLogVerbose(@"Resuming RAW processing for %@ from stage 5", image.uuid);
		
		state.progress = [NSProgress progressWithTotalUnitCount:6];
		if(outProgress) *outProgress = state.progress;
		
		[self resumePipelineRunWithCachedData:state shouldCacheResults:cache];
	} else {
		state.progress = [NSProgress progressWithTotalUnitCount:11];
		if(outProgress) *outProgress = state.progress;
		
		[self beginFullPipelineRunWithState:state shouldCacheResults:cache];
	}
}

#pragma mark - RAW Processing Steps
#pragma mark Interpolation and Data Reading
/**
 * Creates the block operation to debayer the RAW data. This is accomplished
 * by calling the "unpackRawData" method on the RAW file handle.
 */
- (NSBlockOperation *) opDebayer:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Debayering");
		
		NSError *err = nil;
		
		state.stage = TSRawPipelineStageDebayering;
		
		// unpack image data
		if([state.rawImage unpackRawData:&err] != YES) {
			DDLogError(@"Error unpacking raw data: %@", err);
			
			[state terminateWithError:err];
			
			TSEndOperation();
			return;
		}
		
		TSEndOperation();
	}];
	
	op.name = @"Debayering";
	return op;
}

/**
 * Decodes the raw Bayer data from the raw file into RGB data that can be
 * operated on.
 *
 * This involves:
 * 1. Subtracting a dark frame (hot pixel removal)
 * 2. Adjusting the black level
 * 3. Performing interpolation
 */
- (NSBlockOperation *) opDemosaic:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Demosaic");
		
		state.stage = TSRawPipelineStageDemosaicing;
		libraw_data_t *libRaw = state.rawImage.libRaw;
		
		// copy RAW data into buffer
		[state.rawImage copyRawDataToBuffer:self.interpolatedColourBuf];
		
		// adjust black level
		TSRawAdjustBlackLevel(libRaw, (uint16_t (*)[4]) self.interpolatedColourBuf);
		TSRawSubtractBlack(libRaw, (uint16_t (*)[4]) self.interpolatedColourBuf);
		
		
		// white balance (colour scaling) and pre-interpolation
		state.stage = TSRawPipelineStageWhiteBalance;
		
		TSRawPreInterpolationApplyWB(libRaw, (uint16_t (*)[4]) self.interpolatedColourBuf);
		TSRawPreInterpolation(libRaw, (uint16_t (*)[4]) self.interpolatedColourBuf);
		
		
		// interpolate colour data
		state.stage = TSRawPipelineStageInterpolateColour;
		
		ahd_interpolate_mod(libRaw, (uint16_t (*)[4]) self.interpolatedColourBuf);
//		lmmse_interpolate(libRaw, (uint16_t (*)[4]) self.interpolatedColourBuf);
		
		TSEndOperation();
	}];
	
	op.name = @"Demosaicing and Interpolation";
	return op;
}

/**
 * Converts from the (potentially lens corrected) camera colour space to the
 * internal working colour space, and corrects the gamma curve of the image.
 */
- (NSBlockOperation *) opGammaColourSpaceCorrect:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Colour Profile Conversion and Gamma Adjustment");
		
		state.stage = TSRawPipelineStageConvertToRGB;
		libraw_data_t *libRaw = state.rawImage.libRaw;
		
		// convert to RGB
		state.stage = TSRawPipelineStageConvertToRGB;
		TSRawConvertToRGB(libRaw,
						  (uint16_t (*)[4]) self.interpolatedColourBuf, // input -> RGBX
						  (uint16_t (*)[3]) self.interpolatedColourBuf, // output -> RGB
						  state.histogramBuf, state.gammaCurveBuf);
		
		
#if WriteDebugData
		// save buffer to disk (debug testing)
		NSFileManager *fm = [NSFileManager defaultManager];
		NSURL *appSupportURL = [TSGroupContainerHelper sharedInstance].appSupport;
		
		NSData *rawData = [NSData dataWithBytesNoCopy:self.interpolatedColourBuf length:(state.rawImage.size.width * 3 * 2) * state.rawImage.size.height freeWhenDone:NO];
		[rawData writeToURL:[appSupportURL URLByAppendingPathComponent:@"test_raw_data.raw"] atomically:NO];
		
		// write thumbnail extracted from image
		rawData = [state.rawImage.thumbnail TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:1.f];
		[rawData writeToURL:[appSupportURL URLByAppendingPathComponent:@"test_raw_thumb.tiff"] atomically:NO];
		
		// write histogram and curves
		rawData = [NSData dataWithBytesNoCopy:state.histogramBuf length:0x2000 * 4 * sizeof(int) freeWhenDone:NO];
		[rawData writeToURL:[appSupportURL URLByAppendingPathComponent:@"test_raw_histo.bin"] atomically:NO];
		
		
		rawData = [NSData dataWithBytesNoCopy:state.gammaCurveBuf length:0x10000 * sizeof(uint16_t) freeWhenDone:NO];
		[rawData writeToURL:[appSupportURL URLByAppendingPathComponent:@"test_raw_gcurv.bin"] atomically:NO];
		
		
		rawData = [NSData dataWithBytesNoCopy:libRaw->color.curve length:0x10000 * sizeof(uint16_t) freeWhenDone:NO];
		[rawData writeToURL:[appSupportURL URLByAppendingPathComponent:@"test_raw_tcurv.bin"] atomically:NO];
		
		DDLogVerbose(@"Finished writing debug data");
#endif
		
		TSEndOperation();
	}];
	
	op.name = @"Colour Profile Conversion and Gamma Adjustment";
	return op;
}

#pragma mark Lens Corrections
/**
 * Performs lens correction.
 */
- (NSBlockOperation *) opLensCorrect:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Lens Corrections");
		
		// only perform lens corrections if, well… they're desired
		if(state.applyLensCorrections) {
			state.stage = TSRawPipelineStageLensCorrection;
			
			NSUInteger x, y, step;
			
			lfModifier *m = state.lcModifier;
			
			/**
			 * Lens corrections consist of two steps: First, vignetting removal,
			 * then geometry/distortion and TCA correction. Each step operates
			 * on a single scanline in the image at a time. After all scanlines
			 * for a particular step have been operated on, the next step will
			 * be operated on.
			 */
			for(step = 0; step < 2; step++) {
				// set up some variables
				BOOL ok = YES;
				
				// dst will be filled by 48bpp RGB data
				uint16_t *dst = (uint16_t *) TSPixelConverterGetRGBXPointer(state.converter);
				// imgData is the original 48bpp RGB data
				uint16_t *imgData = (uint16_t *) self.interpolatedColourBuf;
				int imgDataStride = state.rawSize.width * 3 * sizeof(uint16_t);
				
				// allocate the coordinate buffer for subpixel coordinates
				size_t subPixelCoordsSz = sizeof(float) * 3 * 2 * state.rawSize.width;

				float *subPixelCoords = (float *) valloc(subPixelCoordsSz);
				memset(subPixelCoords, 0, subPixelCoordsSz);
				
				
				// perform the step for each scanline separately
				for(y = 0; (ok && (y < state.rawSize.height)); y++) {
					// remove vignetting
					if(step == 0) {
						ok = m->ApplyColorModification(imgData, 0, y,
													   state.rawSize.width, 1,
													   LF_CR_3(RED,BLUE,GREEN), imgDataStride);
					}
					
					// correct geometry and TCA
					else if(step == 1) {
						ok = m->ApplySubpixelGeometryDistortion(0, y,
																state.rawSize.width,
																1, subPixelCoords);
						// interpolate the pixels into output buffer
						if(ok) {
							float *src = subPixelCoords;
							
							for(x = 0; x < state.rawSize.width; x++) {
								// copy the RGB pixels individually
								*dst++ = TSInterpolatePixelBilinear(imgData, imgDataStride, src[0], src[1]);
								*dst++ = TSInterpolatePixelBilinear(imgData, imgDataStride, src[2], src[3]);
								*dst++ = TSInterpolatePixelBilinear(imgData, imgDataStride, src[4], src[5]);
								
								// increment the src pointer
								src += (2 * 3);
							}
						}
					}
					
					// unknown step
					else {
						DDLogWarn(@"Invalid lens correction step: %lu", (unsigned long) step);
					}
					
					// increment the input and output pointers
					imgData += ((size_t) (3 * state.rawSize.width));
					dst += ((size_t) (3 * state.rawSize.width));
				}
			}
		}
		
		TSEndOperation();
	}];
	
	op.name = @"Lens Corrections";
	return op;
}

#pragma mark Pixel Format Conversions
/**
 * Converts the image from the 16 bit/component unsigned short RGB format to
 * a 32 bit/component floating-point RGBA format.
 */
- (NSBlockOperation *) opConvertToPlanar:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Convert to Planar Floating Point");
		
		state.stage = TSRawPipelineStageConvertToPlanar;
		
		// if lens corrections were applied, the data is in the converter output
		if(state.applyLensCorrections == YES) {
			size_t num_bytes = (state.rawSize.width * 3 * sizeof(uint16_t)) * state.rawSize.height;
			void *correctedData = TSPixelConverterGetRGBXPointer(state.converter);
			
			// we must copy the data; otherwise, it'll explode!
			memcpy(self.interpolatedColourBuf, correctedData, num_bytes);
		}
		
		// set the input buffer and begin converting
		TSPixelConverterSetInData(state.converter, self.interpolatedColourBuf);
		
		// convert; the gamma curve normalized values with a max of 0xFFFF
		TSPixelConverterRGB16UToFloat(state.converter, 0xFFFF);
		TSPixelConverterRGBFFFToPlanarF(state.converter);
		
		TSEndOperation();
	}];
	
	op.name = @"Conver to Planar Floating Point";
	return op;
}

/**
 * Converts planar RGB floating-point data to interleaved RGBA. The alpha
 * component is fixed at 1.f.
 */
- (NSBlockOperation *) opConvertToInterleaved:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Convert to Interleaved Floating Point");
		
		state.stage = TSRawPipelineStageConvertToInterleaved;
		
		// do the conversion from planar to interleaved
		TSPixelConverterPlanarFToRGBXFFFF(state.converter);
		
#if	WriteDebugData
		[self dumpImageBufferInterleaved:state];
#endif
		
		// create CIImage
		state.coreImageInput = [self ciImageFromPixelConverter:state.converter
													   andSize:state.outputSize];
		
		TSEndOperation();
	}];
	
	op.name = @"Convert to Interleaved Floating Point";
	return op;
}


/**
 * Creates a CIImage from the state's bitmap converter output.
 */
- (CIImage *) ciImageFromPixelConverter:(TSPixelConverterRef) converter andSize:(NSSize) outputSize {
	NSBitmapImageRep *bm;
	CIImage *im;
	
	// get info about the input buffer
	NSUInteger bytesPerRow = TSPixelConverterGetRGBXStride(converter);
	void *buf = TSPixelConverterGetRGBXPointer(converter);
	
	// create bitmap representation, and re-tag with colour space
	unsigned char *ptrs = { ((unsigned char *) buf) };
	
	bm = [[NSBitmapImageRep alloc]
		  initWithBitmapDataPlanes:&ptrs
		  pixelsWide:outputSize.width
		  pixelsHigh:outputSize.height
		  bitsPerSample:32
		  samplesPerPixel:4
		  hasAlpha:YES
		  isPlanar:NO
		  colorSpaceName:NSCalibratedRGBColorSpace
		  bitmapFormat:NSFloatingPointSamplesBitmapFormat
		  bytesPerRow:bytesPerRow
		  bitsPerPixel:128];
	
	// DDLogVerbose(@"Output size = %@, bytes/row = %lu", NSStringFromSize(outputSize), bytesPerRow);
	
	NSColorSpace *proPhoto = [NSColorSpace proPhotoRGBColorSpace];
	bm = [bm bitmapImageRepByRetaggingWithColorSpace:proPhoto];
	
	// create a CIImage
	im = [[CIImage alloc] initWithBitmapImageRep:bm];
	DDAssert(im != nil, @"Couldn't create CIImage from NSBitmapImageRep");
	
	// done
	return im;
	
	
//	// get info about the input buffer
//	NSUInteger bytesPerRow = TSPixelConverterGetRGBXStride(converter);
//	void *buf = TSPixelConverterGetRGBXPointer(converter);
//	
//	NSUInteger bufSz = bytesPerRow * outputSize.height;
//	
//	CGColorSpaceRef proPhoto = [NSColorSpace proPhotoRGBColorSpace].CGColorSpace;
//	
//	// create an NSData wrapper
//	NSData *data = [[NSData alloc] initWithBytesNoCopy:buf length:bufSz
//										  freeWhenDone:NO];
//	
//	// create the image
//	im = [CIImage imageWithBitmapData:data bytesPerRow:bytesPerRow size:outputSize
//							   format:kCIFormatRGBAf colorSpace:proPhoto];
//	return im;
}

#pragma mark vImage Steps
/**
 * Rotates or flips the image to account for the camera's orientation.
 */
- (NSBlockOperation *) opRotateFlip:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Rotation and Flipping");
		
		state.stage = TSRawPipelineStageRotationFlip;
		
		// do we need to apply rotation?
		if(state.rawImage.rotation == 0) {
			TSEndOperation();
			return;
		}
		
		// calculate the correct rotation angle
		NSInteger rotation = state.rawImage.rotation;
		
		if(rotation < 0) {
			rotation = 360 - rotation;
		}
		
		// if rotation is not 0° or 180°, swap size
		if(rotation != 0 && rotation != 180) {
			NSSize regularSize = state.outputSize;
			state.outputSize = NSMakeSize(regularSize.height, regularSize.width);
		}
		
		// perform the rotation
		TSPixelConverterRotate90(state.converter, (rotation / 90));
		
		TSEndOperation();
	}];
	
	op.name = @"Rotation and Flipping";
	return op;
}

/**
 * Applies convolution kernels on the image.
 */
- (NSBlockOperation *) opConvolve:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Convolution");
		
		state.stage = TSRawPipelineStageConvolution;
		
		// apply sharpening and other kernels?
		
		TSEndOperation();
	}];
	
	op.name = @"Convolution";
	return op;
}

/**
 * Applies morphological operations on the image.
 */
- (NSBlockOperation *) opMorphological:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Morphological");
		
		state.stage = TSRawPipelineStageMorphological;
		
		TSEndOperation();
	}];
	
	op.name = @"Morphological";
	return op;
}

/**
 * Adjusts the histogram.
 */
- (NSBlockOperation *) opHistogramAdjust:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Histogram Adjustment");
		
		state.stage = TSRawPipelineStageHistogramModification;
		
		TSEndOperation();
	}];
	
	op.name = @"Histogram Adjustments";
	return op;
}

#pragma mark CoreImage Filtering
/**
 * Applies all required CoreImage filters.
 */
- (NSBlockOperation *) opCoreImageFilters:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"CoreImage Filters");
		
		NSImage *im;
		TSCoreImagePipelineJob *job;
		
		state.stage = TSRawPipelineStageCoreImageFilter;
		
		// Produce a job object
		job = [[TSCoreImagePipelineJob alloc] initWithInput:state.coreImageInput];
		
		// Create the filter chain (run on image MOC's queue)
		[state.mocCtx performBlockAndWait:^{
			[state.image TSCIPipelineSetUpJob:job];
		}];
		
		// Render the image as appropriate
		TSCoreImagePixelFormat fmt = TSCIPixelFormatRGBA8;
		
		switch(state.outFormat) {
			// Use 16-bit RGBA
			case TSRawPipelineOutputFormatNSImage16Bit:
				fmt = TSCIPixelFormatRGBA16;
			
			// Use 8-bit RGBA
			case TSRawPipelineOutputFormatNSImage8Bit: {
				// determine output colour space
				NSColorSpace *space = [NSColorSpace sRGBColorSpace];
				
				// Process image
				im = [self.ciPipeline produceNSImageFromJob:job
											withPixelFormat:fmt
											 andColourSpace:space];
				state.cpuResult = im;
				
				// Execute success callback
				[state completeWithImage:state.cpuResult];
				
				break;
			}
			
			// Handle any unknown formats; this shouldn't happen
			default:
				DDLogError(@"Unsupported output format: %lu", state.outFormat);
		}
		
		TSEndOperation();
	}];
	
	op.name = @"CoreImage Filters";
	return op;
}

#pragma mark - Caching Support
/**
 * Performs a full run of the RAW pipeline, without taking into account any
 * previously cached data.
 */
- (void) beginFullPipelineRunWithState:(TSRawPipelineState *) state shouldCacheResults:(BOOL) cache {
	NSBlockOperation *opDebayer, *opDemosaic, *opLensCorrect, *opConvertPlanar;
	NSBlockOperation *opRotate, *opConvolute, *opMorphological, *opHisto;
	NSBlockOperation *opConvertInterleaved, *opCoreImage, *opConvertRGBGamma;
	NSBlockOperation *opUpdateCache, *opCleanUp;
	
	// Set up the various operations
	opDebayer = [self opDebayer:state];
	opDemosaic = [self opDemosaic:state];
	opLensCorrect = [self opLensCorrect:state];
	opConvertRGBGamma = [self opGammaColourSpaceCorrect:state];
	
	opConvertPlanar = [self opConvertToPlanar:state];
	
	opRotate = [self opRotateFlip:state];
	opConvolute = [self opConvolve:state];
	opMorphological = [self opMorphological:state];
	opHisto = [self opHistogramAdjust:state];
	
	opConvertInterleaved = [self opConvertToInterleaved:state];
	
	opCoreImage = [self opCoreImageFilters:state];
	
	opCleanUp = [self opCleanUp:state];
	
	// If caching is enabled, create the cache updating operations
	if(cache) {
		opUpdateCache = [self opStorePlanarInCache:state];
	}
	
	// Set up interdependencies between the operations
	[opDemosaic addDependency:opDebayer];
	[opLensCorrect addDependency:opDemosaic];
	[opConvertRGBGamma addDependency:opLensCorrect];
	
	[opConvertPlanar addDependency:opConvertRGBGamma];
	
	if(cache) {
		[opUpdateCache addDependency:opConvertPlanar];
		[opRotate addDependency:opUpdateCache];
	} else {
		[opRotate addDependency:opConvertPlanar];
	}
	
	[opConvolute addDependency:opRotate];
	[opMorphological addDependency:opConvolute];
	[opHisto addDependency:opMorphological];
	
	[opConvertInterleaved addDependency:opHisto];
	
	[opCoreImage addDependency:opConvertInterleaved];
	
	[opCleanUp addDependency:opCoreImage];
	
	// Add them to the queue to vamenos the operations
	TSAddOperation(opDebayer, state);
	TSAddOperation(opDemosaic, state);
	TSAddOperation(opLensCorrect, state);
	TSAddOperation(opConvertRGBGamma, state);
	TSAddOperation(opConvertPlanar, state);
	
	if(cache) {
		TSAddOperation(opUpdateCache, state);
	}
	
	TSAddOperation(opRotate, state);
	TSAddOperation(opConvolute, state);
	TSAddOperation(opMorphological, state);
	TSAddOperation(opHisto, state);
	
	TSAddOperation(opConvertInterleaved, state);
	
	TSAddOperation(opCoreImage, state);
	
	TSAddOperation(opCleanUp, state);
}

/**
 * Resumes RAW processing with the cached output of stage 5; this will run
 * all vImage and CoreImage operations.
 */
- (void) resumePipelineRunWithCachedData:(TSRawPipelineState *) state shouldCacheResults:(BOOL) cache {
	NSBlockOperation *opRotate, *opConvolute, *opMorphological, *opHisto;
	NSBlockOperation *opConvertInterleaved, *opCoreImage,  *opRestoreCache;
	NSBlockOperation *opCleanUp;
	
	// Set up the various operations
	opRestoreCache = [self opRestorePlanarFromCache:state];
	
	opRotate = [self opRotateFlip:state];
	opConvolute = [self opConvolve:state];
	opMorphological = [self opMorphological:state];
	opHisto = [self opHistogramAdjust:state];
	
	opConvertInterleaved = [self opConvertToInterleaved:state];
	
	opCoreImage = [self opCoreImageFilters:state];
	opCleanUp = [self opCleanUp:state];
	
	// set up interdependencies between the operations
	[opRotate addDependency:opRestoreCache];
	
	[opConvolute addDependency:opRotate];
	[opMorphological addDependency:opConvolute];
	[opHisto addDependency:opMorphological];
	
	[opConvertInterleaved addDependency:opHisto];
	
	[opCoreImage addDependency:opConvertInterleaved];
	[opCleanUp addDependency:opCoreImage];
	
	// Add them to the queue to vamenos the operations
	TSAddOperation(opRestoreCache, state);
	
	TSAddOperation(opRotate, state);
	TSAddOperation(opConvolute, state);
	TSAddOperation(opMorphological, state);
	TSAddOperation(opHisto, state);
	
	TSAddOperation(opConvertInterleaved, state);
	
	TSAddOperation(opCoreImage, state);
	TSAddOperation(opCleanUp, state);
}

#pragma mark Cache Handling
/**
 * Invalidates the internal caches of an image.
 */
- (void) clearCachesForImage:(nonnull TSLibraryImage *) inImage {
	[inImage.managedObjectContext performBlock:^{
		[self.cache evictDataForUuid:inImage.uuid];
	}];
}

#pragma mark Cache Encoding
/**
 * Stores a copy of the image buffer into the cache.
 */
- (void) storeFloatDataCached:(TSRawPipelineState *) state {
	// get how many kerjiggers each plane is
	vImage_Buffer plane = TSPixelConverterGetPlanevImageBufferBuffer(state.converter, 0);
	NSUInteger planeBytes = plane.rowBytes * plane.height;
	
	NSMutableData *buffer = [NSMutableData dataWithCapacity:planeBytes * 3];
	
	DDLogDebug(@"Allocated %lu bytes for raw cache", planeBytes * 3);
	
	// make a copy of each of the planes
	for(NSUInteger idx = 0; idx < 3; idx++) {
		plane = TSPixelConverterGetPlanevImageBufferBuffer(state.converter, idx);
		[buffer appendBytes:plane.data length:planeBytes];
	}
	
	// store in the cache
	[self.cache setData:buffer forUuid:state.imageUuid];
}

#pragma mark Cache Decoding
/**
 * Reads the planar buffer cache, dissects it back into the three original
 * planes, and copies that data back into the planes.
 */
- (void) restoreFloatDataCached:(TSRawPipelineState *) state {
	NSUInteger offset, planeBytes;
	
	// get the cached data
	NSData *cachedData = [self.cache cachedDataForUuid:state.imageUuid];
	
	if(cachedData == nil) {
		DDLogError(@"Cache lost its data for this image since operation was started… this is bad.");
	}
	
	// calculate plane size and get buffer
	vImage_Buffer plane = TSPixelConverterGetPlanevImageBufferBuffer(state.converter, 0);
	planeBytes = plane.rowBytes * plane.height;
	
	// make a copy of each of the planes
	for(NSUInteger idx = 0; idx < 3; idx++) {
		plane = TSPixelConverterGetPlanevImageBufferBuffer(state.converter, idx);
		offset = idx * planeBytes;
		
		[cachedData getBytes:plane.data range:NSMakeRange(offset, planeBytes)];
	}
}

/**
 * Restores the half-sized planar data from the buffer, copying it into the
 * image converter. This also ensures the sizes are properly handled, and that
 * any structs that rely on the image's size are scaled.
 */
- (void) restoreHalfSizeFloatDataCached:(TSRawPipelineState *) state {
	NSUInteger offset, planeBytes;
	vImage_Error err = kvImageNoError;
	 
	 // get the cached data
	 NSData *cachedData = [self.cache cachedDataForUuid:state.imageUuid];
	 
	 if(cachedData == nil) {
		DDLogError(@"Cache lost its data for this image since operation was started… this is bad.");
	 }
	
	// calculate the size of a large, original-sized plane
	vImage_Buffer planeIn = TSPixelConverterGetPlanevImageBufferBuffer(state.converter, 0);
	planeBytes = planeIn.rowBytes * planeIn.height;
	
	
	// update the raw (input pixel) size
	NSSize newSize;
	
	newSize.width = floor(state.rawSize.width / 2.f);
	newSize.height = floor(state.rawSize.height / 2.f);
	
	state.rawSize = newSize;
	
	// update output size
	newSize.width = floor(state.outputSize.width / 2.f);
	newSize.height = floor(state.outputSize.height / 2.f);
	
	state.outputSize = newSize;
	
	DDLogVerbose(@"Resuming cached raw processing, size %@", NSStringFromSize(newSize));
	
	// resize the pixel converter to the half size
	TSPixelConverterResize(state.converter, state.rawSize.width, state.rawSize.height);
	
	
	// calculate size of temporary vImage buffer and allocate it
	vImage_Buffer planeOut = TSPixelConverterGetPlanevImageBufferBuffer(state.converter, 0);
	
	void *vImageTemp = NULL;
	err = vImageScale_PlanarF(&planeIn, &planeOut, NULL, kvImageGetTempBufferSize);
	
	if(err > 0) {
		vImageTemp = (void *) valloc(err);
	} else {
		DDLogError(@"Couldn't get size of temp buffer for scaling, error %lu", err);
		return;
	}
	
	
	// read out full size data in, scale, copy into pixel converter's buffer
	for(NSUInteger idx = 0; idx < 3; idx++) {
		// get the output plane
		planeOut = TSPixelConverterGetPlanevImageBufferBuffer(state.converter, idx);
		
		// set the input plane up
		offset = idx * planeBytes;
		planeIn.data = ((uint8_t *) cachedData.bytes) + offset;
		
		// perform scale operation
		err = vImageScale_PlanarF(&planeIn, &planeOut, vImageTemp, kvImageNoFlags);
		
		// check for error
		if(err != kvImageNoError) {
			DDLogError(@"Error during scaling operation: %lu", err);
			
			// clean up and exit
			free(vImageTemp);
			return;
		}
	}
	
	// clean up
	free(vImageTemp);
}

#pragma mark Cache Operations
/**
 * Creates an operation that stores the planar floating point pixel data in the
 * data cache.
 */
- (NSBlockOperation *) opStorePlanarInCache:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Update Cache");
		
		// if not caching, exit
		if(state.shouldCache == NO) {
			TSEndOperation();
			return;
		}
		
		[self storeFloatDataCached:state];
		
		TSEndOperation();
	}];
	
	op.name = @"Update Cache";
	return op;
}

/**
 * Returns an operation that pulls the cached floating-point data out of the
 * cache, and copies it back into the data planes.
 */
- (NSBlockOperation *) opRestorePlanarFromCache:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Restore Cached State");
		
		// if not caching, exit
		if(state.shouldCache == NO) {
			TSEndOperation();
			return;
		}
		
		// if NOT fast display, use full size data
		if(state.intent != TSRawPipelineIntentDisplayFast) {
			[self restoreFloatDataCached:state];
		} else {
			[self restoreHalfSizeFloatDataCached:state];
		}
		
		TSEndOperation();
	}];
	
	op.name = @"Restore Cached State";
	return op;
}

#pragma mark - Memory Management and Housekeeping
/**
 * Performs any needed cleanup on the pipeline, once complete.
 */
- (NSBlockOperation *) opCleanUp:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		TSBeginOperation(@"Clean Up");
		
		// deallocate buffers
		[self cleanUpState:state];
		
		TSEndOperation();
	}];
	
	op.name = @"Clean Up";
	return op;
}

/**
 * De-allocates any buffers that have previously been allocated in the state
 * object.
 */
- (void) cleanUpState:(TSRawPipelineState *) state {
	// de-reference the images
	state.image = nil;
	state.rawImage = nil;
	
	state.coreImageInput = nil;
	state.cpuResult = nil;
	
	// free various other allocated buffers
	free(state.histogramBuf);
	free(state.gammaCurveBuf);
}

#pragma mark - Debugging Helpers
/**
 * Dumps the floating point image buffer of the given pipeline stage to a
 * TIFF file in the Application Support directory.
 */
- (void) dumpImageBufferInterleaved:(TSRawPipelineState *) state {
	NSURL *appSupportURL = [TSGroupContainerHelper sharedInstance].appSupport;
	
	void *buffer = TSPixelConverterGetRGBXPointer(state.converter);
	
	// create a bitmap rep
	NSBitmapImageRep *bm;
	unsigned char *ptrs = { ((unsigned char*) buffer) };
	
	bm = [[NSBitmapImageRep alloc]
		  initWithBitmapDataPlanes:&ptrs
		  pixelsWide:state.outputSize.width
		  pixelsHigh:state.outputSize.height
		  bitsPerSample:32
		  samplesPerPixel:4
		  hasAlpha:YES
		  isPlanar:NO
		  colorSpaceName:NSCustomColorSpace
		  bitmapFormat:NSFloatingPointSamplesBitmapFormat
		  bytesPerRow:TSPixelConverterGetRGBXStride(state.converter)
		  bitsPerPixel:128];
	
	// tag it with the colour space
	NSColorSpace *colourSpace = [NSColorSpace proPhotoRGBColorSpace];
	bm = [bm bitmapImageRepByRetaggingWithColorSpace:colourSpace];
	
	[[bm TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:1] writeToURL:[appSupportURL URLByAppendingPathComponent:@"raw_pipeline_tagged.tiff"] atomically:NO];
}

/**
 * Dumps the CoreImage `CIImage` object in the state struct.
 */
- (void) dumpImageBufferCoreImage:(TSRawPipelineState *) state {
	NSBitmapImageRep *rep;
	NSData *tiff;
	
	NSURL *appSupportURL = [TSGroupContainerHelper sharedInstance].appSupport;
	
	// get the representation, TIFF data, and write it
	rep = [[NSBitmapImageRep alloc] initWithCIImage:state.coreImageInput];
	
	tiff = [rep TIFFRepresentationUsingCompression:NSTIFFCompressionNone
											factor:1];
	
	[tiff writeToURL:[appSupportURL URLByAppendingPathComponent:@"raw_pipeline_coreimage_tagged.tiff"] atomically:YES];
}

@end
