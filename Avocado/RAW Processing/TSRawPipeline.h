//
//  TSRawPipeline.h
//  Avocado
//
//	This class is used in processing RAW files. It performs a variety of
//	tasks, in a defined order.
//
//  Created by Tristan Seifert on 20160502.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

/*
 * The image pipeline takes the raw Bayer data from the sensor, and converts
 * it into usable RGB data that can be processed much more conveniently.
 *
 * Note that up until step 4, data will be in a 16 bit/component unsigned
 * integer (RGB; 48bpp) format; after applying lens corrections, the image
 * buffer is converted to planar 32b floating point RGB. After step 8 is
 * completed, it is converted to chunky 32b floating point RGBX (128bpp).
 *
 *	1. Debayering of RAW data
 *	2. Demosaicing Bayer data
 *		a. Apply white balance
 *		b. Interpolate colour values for missing pixels
 *	3. Apply lens corrections (using LensFun library)
 *		a. Devignetting
 *		b. Geometry corrections (scaling, projection, distortion, chromatic
 *		abberations)
 *	4. Gamma correction and colour space conversion
 *	5. Convert to planar floating point
 *	6. vImage rotation/flip (to account for flipped status of image)
 *	7. vImage (de)convolution operations
 *	8. vImage 'morphological' operations
 *	9. vImage histogram operations (exposure, contrast, etc.)
 * 10. Convert to interleaved RGBA floating-point
 * 11. CoreImage filter pass
 *		a. Noise reduction, blurs
 *		b. Sharpening (luminance, unsharp mask)
 *		c. Colour adjustments and effects
 *		d. Distortion effects
 *		e. Geometry adjustments (crop, scaling, straightening, etc.)
 *		f. Vignetting and grain
 *
 * The output of stage 5 is cached.
 *
 * Pipeline plugins can chose to process data at any major numbered
 * position in the pipeline. They are called _before_ the built-in pipeline
 * step.
 */

#import <Foundation/Foundation.h>

/**
 * Output formats of the raw pipeline. This determines whether the
 * resultant image is copied to the CPU (as an NSImage) or will stay
 * on the GPU to be displayed on-screen (via Metal).
 */
typedef NS_ENUM(NSUInteger, TSRawPipelineOutputFormat) {
	/**
	 * Renders the image into a bitmap context on the CPU. The
	 * precise implementation details of how CoreImage does this are
	 * unknown; however, this will entail reading the entire image
	 * out of VRAM, performing pixel conversions, and allocating
	 * memory on the CPU side.
	 *
	 * It can be specified what bit depth (8 or 16 bits/component)
	 * the output image will have. By default, it will use 8 bits.
	 *
	 * @note This should only really be used when the final intent
	 * is to write the image to a file.
	 */
	TSRawPipelineOutputFormatNSImage8Bit,
	TSRawPipelineOutputFormatNSImage16Bit,
	
	TSRawPipelineOutputFormatNSImage = TSRawPipelineOutputFormatNSImage8Bit,
	
	/**
	 * The image is rendered into a Metal texture, which is used by
	 * the GPU-accelerated image display view. This avoids the costly
	 * transfer of pixel data from VRAM, as well as any potential
	 * format conversion that the CPU may need to perform before the
	 * image is blitted onto the screen.
	 */
	TSRawPipelineOutputFormatGPU
};

/**
 * Various rendering intents for which the raw pipeline may be able
 * to use different optimizations for.
 *
 * For example, using the 'fast display' mode may allow the pipeline
 * to downscale pixel data, or use faster, less precise algorithms in
 * the computation of pixel data.
 */
typedef NS_ENUM(NSUInteger, TSRawPipelineIntent) {
	TSRawPipelineIntentUnknown,
	
	/**
	 * Fast display; outputs an image that is half the resolution of
	 * the input image. Scaling, rotation, and colour conversions are
	 * performed with less precision.
	 */
	TSRawPipelineIntentDisplayFast,
	
	/**
	 * Slow display: Uses the full size image, and high quality algo-
	 * rithms optimized for on-screen display.
	 */
	TSRawPipelineIntentDisplaySlow,
	
	/**
	 * Output: Produces an image using the highest quality algorithms
	 * available to the pipeline, with a higher bit depth than the
	 * screen output modes provide.
	 */
	TSRawPipelineIntentOutput
};

/**
 * An enumeration declaring the current stage in the processing pipeline. As
 * some steps may have sub-steps that each can take a considerable amount of
 * time, the high 16 bits contain the step number, while the low 16 bits
 * contain the substep.
 */
typedef NS_ENUM(NSUInteger, TSRawPipelineStage) {
	TSRawPipelineStageInitializing			= 0,
	
	TSRawPipelineStageDebayering			= (1 << 16),
	
	TSRawPipelineStageDemosaicing			= (2 << 16),
	TSRawPipelineStageWhiteBalance			= (2 << 16) | 1,
	TSRawPipelineStageInterpolateColour		= (2 << 16) | 2,
	
	TSRawPipelineStageLensCorrection		= (3 << 16),
	TSRawPipelineStageLensVignetting		= (3 << 16) | 1,
	TSRawPipelineStageLensDistortions		= (3 << 16) | 2,
	
	TSRawPipelineStageConvertToRGB			= (4 << 16),
	
	TSRawPipelineStageConvertToPlanar		= (5 << 16),
	
	TSRawPipelineStageRotationFlip			= (6 << 16),
	TSRawPipelineStageConvolution			= (7 << 16),
	TSRawPipelineStageMorphological			= (8 << 16),
	TSRawPipelineStageHistogramModification	= (9 << 16),
	
	TSRawPipelineStageConvertToInterleaved	= (10 << 16),
	
	TSRawPipelineStageCoreImageFilter		= (11 << 16),
};

/// mask for the major pipeline stage
#define TSRawPipelineMajorStageMask			0xFFFF0000
/// mask for the minor pipeline stage
#define TSRawPipelineMinorStageMask			0x0000FFFF

/**
 * Callback to be executed when an image has been completely processed.
 *
 * @note If an error occurs during conversion, the image object will be nil,
 * while the error object will have any relevant information within.
 *
 * @note The colour space and bit depth of the image are not guaranteed.
 */
typedef void (^TSRawPipelineCompletionCallback)(NSImage * _Nullable, NSError * _Nullable);

/**
 * Callback to be executed with progress information for the processing of
 * the given file. Each time this callback is invoked, it will be with a new
 * stage flag.
 */
typedef void (^TSRawPipelineProgressCallback)(TSRawPipelineStage);


@class TSRawImage, TSLibraryImage;
@interface TSRawPipeline : NSObject

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
	  renderingIntent:(TSRawPipelineIntent) intent
		 outputFormat:(TSRawPipelineOutputFormat) outFormat
   completionCallback:(nonnull TSRawPipelineCompletionCallback) complete
	 progressCallback:(nullable TSRawPipelineProgressCallback) progress
   conversionProgress:(NSProgress * _Nonnull * _Nullable) outProgress;

/**
 * Invalidates the internal caches of an image. This is automatically called
 * when the cached image is different than the image for which a RAW processing
 * is requested.
 */
- (void) clearImageCaches;

@end
