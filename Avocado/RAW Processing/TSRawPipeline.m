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

#import "TSPixelFormatConverter.h"
#import "TSRawImageDataHelpers.h"
#import "lmmse_interpolate.h"

#import "TSHumanModels.h"

#import "NSBlockOperation+AvocadoUtils.h"
#import "NSColorSpace+ExtraColourSpaces.h"

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

/// CoreImage pipeline
@property (nonatomic) TSCoreImagePipeline *ciPipeline;

// helpers
- (NSBlockOperation *) opDebayer:(TSRawPipelineState *) state;
- (NSBlockOperation *) opDemosaic:(TSRawPipelineState *) state;
- (NSBlockOperation *) opLensCorrect:(TSRawPipelineState *) state;

- (NSBlockOperation *) opConvertToPlanar:(TSRawPipelineState *) state;

- (NSBlockOperation *) opRotateFlip:(TSRawPipelineState *) state;
- (NSBlockOperation *) opConvolve:(TSRawPipelineState *) state;
- (NSBlockOperation *) opMorphological:(TSRawPipelineState *) state;
- (NSBlockOperation *) opHistogramAdjust:(TSRawPipelineState *) state;

- (NSBlockOperation *) opConvertToInterleaved:(TSRawPipelineState *) state;

- (NSBlockOperation *) opCoreImageFilters:(TSRawPipelineState *) state;

- (NSBlockOperation *) opGenerateDisplayHistogram:(TSRawPipelineState *) state;

// conversion
- (CIImage *) ciImageFromPixelConverter:(TSPixelConverterRef) converter andSize:(NSSize) outputSize;

// debugging
- (void) dumpImageBufferInterleaved:(TSRawPipelineState *) state;
- (void) dumpImageBufferCoreImage:(TSRawPipelineState *) state;

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
		
		// create CoreImage pipeline
		self.ciPipeline = [TSCoreImagePipeline new];
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
	
	NSBlockOperation *opDebayer, *opDemosaic, *opLensCorrect, *opConvertPlanar;
	NSBlockOperation *opRotate, *opConvolute, *opMorphological, *opHisto;
	NSBlockOperation *opConvertInterleaved, *opCoreImage, *opOutputHistogram;
	
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
	
	state.histogramBuf = valloc(sizeof(int) * 4 * 0x2000);
	state.gammaCurveBuf = valloc(sizeof(uint16_t) * 0x10000);
	
	state.outputSize = state.rawImage.size;
	
	// set up the various operations
	opDebayer = [self opDebayer:state];
	opDemosaic = [self opDemosaic:state];
	opLensCorrect = [self opLensCorrect:state];
	
	opConvertPlanar = [self opConvertToPlanar:state];
	
	opRotate = [self opRotateFlip:state];
	opConvolute = [self opConvolve:state];
	opMorphological = [self opMorphological:state];
	opHisto = [self opHistogramAdjust:state];
	
	opConvertInterleaved = [self opConvertToInterleaved:state];
	
	opCoreImage = [self opCoreImageFilters:state];
	
	opOutputHistogram = [self opGenerateDisplayHistogram:state];
	
	// set up interdependencies between the operations
	[opDemosaic addDependency:opDebayer];
	[opLensCorrect addDependency:opDemosaic];
	
	[opConvertPlanar addDependency:opLensCorrect];
	
	[opRotate addDependency:opConvertPlanar];
	[opConvolute addDependency:opRotate];
	[opMorphological addDependency:opConvolute];
	[opHisto addDependency:opMorphological];
	
	[opConvertInterleaved addDependency:opHisto];
	
	[opCoreImage addDependency:opConvertInterleaved];
	
	[opOutputHistogram addDependency:opCoreImage];
	
	// add them to the queue to vamenos the operations
	TSAddOperation(opDebayer, state);
	TSAddOperation(opDemosaic, state);
	TSAddOperation(opLensCorrect, state);
	
	TSAddOperation(opConvertPlanar, state);
	
	TSAddOperation(opRotate, state);
	TSAddOperation(opConvolute, state);
	TSAddOperation(opMorphological, state);
	TSAddOperation(opHisto, state);
	
	TSAddOperation(opConvertInterleaved, state);
	
	TSAddOperation(opCoreImage, state);
	
	TSAddOperation(opOutputHistogram, state);
}

#pragma mark - RAW Processing Steps
#pragma mark Interpolation and Data Reading
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
		libraw_data_t *libRaw = state.rawImage.libRaw;
		
		// copy RAW data into buffer
		[state.rawImage copyRawDataToBuffer:self.interpolatedColourBuf];
		
		// adjust black level
		TSRawAdjustBlackLevel(libRaw, self.interpolatedColourBuf);
		TSRawSubtractBlack(libRaw, self.interpolatedColourBuf);
		
		
		// white balance (colour scaling) and pre-interpolation
		state.stage = TSRawPipelineStageWhiteBalance;
		
		TSRawPreInterpolationApplyWB(libRaw, self.interpolatedColourBuf);
		TSRawPreInterpolation(libRaw, self.interpolatedColourBuf);
		
		
		// interpolate colour data
		state.stage = TSRawPipelineStageInterpolateColour;
		lmmse_interpolate(libRaw, self.interpolatedColourBuf);
		
		
		// convert to RGB
		state.stage = TSRawPipelineStageConvertToRGB;
		TSRawConvertToRGB(libRaw, self.interpolatedColourBuf, self.interpolatedColourBuf, state.histogramBuf, state.gammaCurveBuf);
		
		
		// save buffer to disk (debug testing)
		NSFileManager *fm = [NSFileManager defaultManager];
		NSURL *appSupportURL = [[fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
		appSupportURL = [appSupportURL URLByAppendingPathComponent:@"me.tseifert.Avocado"];
		
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
	}];
	
	op.name = @"Demosaicing and Interpolation";
	return op;
}

#pragma mark Lens Corrections
/**
 * Performs lens correction.
 */
- (NSBlockOperation *) opLensCorrect:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		state.stage = TSRawPipelineStageLensCorrection;
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
		state.stage = TSRawPipelineStageConvertToPlanar;
		
		// set the input buffer and begin converting
		TSPixelConverterSetInData(state.converter, self.interpolatedColourBuf);
		
		// convert; the gamma curve normalized values with a max of 0xFFFF
		TSPixelConverterRGB16UToFloat(state.converter, 0xFFFF);
		TSPixelConverterRGBFFFToPlanarF(state.converter);
		
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
		state.stage = TSRawPipelineStageConvertToInterleaved;
		
		// do the conversion from planar to interleaved
		TSPixelConverterPlanarFToRGBXFFFF(state.converter);
		[self dumpImageBufferInterleaved:state];
		
		// create CIImage
		state.coreImageInput = [self ciImageFromPixelConverter:state.converter andSize:state.outputSize];
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
	unsigned char *ptrs = { buf };
	
	bm = [[NSBitmapImageRep alloc]
		  initWithBitmapDataPlanes:&ptrs
		  pixelsWide:outputSize.width
		  pixelsHigh:outputSize.height
		  bitsPerSample:32
		  samplesPerPixel:4
		  hasAlpha:YES
		  isPlanar:NO
		  colorSpaceName:NSCustomColorSpace
		  bitmapFormat:NSFloatingPointSamplesBitmapFormat
		  bytesPerRow:bytesPerRow
		  bitsPerPixel:128];
	
	NSColorSpace *proPhoto = [NSColorSpace proPhotoRGBColorSpace];
	bm = [bm bitmapImageRepByRetaggingWithColorSpace:proPhoto];
	
	// create a CIImage
	im = [[CIImage alloc] initWithBitmapImageRep:bm];
	DDAssert(im != nil, @"Couldn't create CIImage from NSBitmapImageRep");
	
	// done
	return im;
}

#pragma mark vImage Steps
/**
 * Rotates or flips the image to account for the camera's orientation.
 */
- (NSBlockOperation *) opRotateFlip:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		state.stage = TSRawPipelineStageRotationFlip;
		
		// do we need to apply rotation?
		if(state.rawImage.rotation == 0) return;
		
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
	}];
	
	op.name = @"Rotation and Flipping";
	return op;
}

/**
 * Applies convolution kernels on the image.
 */
- (NSBlockOperation *) opConvolve:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		state.stage = TSRawPipelineStageConvolution;
		
		// apply sharpening and other kernels?
	}];
	
	op.name = @"Convolution";
	return op;
}

/**
 * Applies morphological operations on the image.
 */
- (NSBlockOperation *) opMorphological:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		state.stage = TSRawPipelineStageMorphological;
	}];
	
	op.name = @"Morphological";
	return op;
}

/**
 * Adjusts the histogram.
 */
- (NSBlockOperation *) opHistogramAdjust:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		state.stage = TSRawPipelineStageHistogramModification;
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
		NSImage *im;
		TSCoreImagePipelineJob *job;
		
		state.stage = TSRawPipelineStageCoreImageFilter;
		
		// produce a job object
		job = [[TSCoreImagePipelineJob alloc] initWithInput:state.coreImageInput];
		
		// process it pls
		im = [self.ciPipeline produceImageFromJob:job
									inPixelFormat:TSCIPixelFormatRGBA16
								   andColourSpace:nil];
		state.result = im;
	}];
	
	op.name = @"CoreImage Filters";
	return op;
}

#pragma mark Output
/**
 * Calculates the final histogram over the image before calling the success
 * callback;
 */
- (NSBlockOperation *) opGenerateDisplayHistogram:(TSRawPipelineState *) state {
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		state.stage = TSRawPipelineStageGenerateHistogram;
		
		// TODO: calculate histogram
		
		// execute success callback
		[state completeWithImage:state.result];
	}];
	
	op.name = @"Display Histogram Calculation";
	return op;
}

#pragma mark - Debugging Helpers
/**
 * Dumps the floating point image buffer of the given pipeline stage to a
 * TIFF file in the Application Support directory.
 */
- (void) dumpImageBufferInterleaved:(TSRawPipelineState *) state {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *appSupportURL = [[fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	appSupportURL = [appSupportURL URLByAppendingPathComponent:@"me.tseifert.Avocado"];
	
	void *buffer = TSPixelConverterGetRGBXPointer(state.converter);
	
	// create a bitmap rep
	NSBitmapImageRep *bm;
	unsigned char *ptrs = { buffer };
	
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
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *appSupportURL = [[fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	appSupportURL = [appSupportURL URLByAppendingPathComponent:@"me.tseifert.Avocado"];
	
	// get the representation, TIFF data, and write it
	rep = [[NSBitmapImageRep alloc] initWithCIImage:state.coreImageInput];
	
	tiff = [rep TIFFRepresentationUsingCompression:NSTIFFCompressionNone
											factor:1];
	
	[tiff writeToURL:[appSupportURL URLByAppendingPathComponent:@"raw_pipeline_coreimage_tagged.tiff"] atomically:YES];
}

@end
