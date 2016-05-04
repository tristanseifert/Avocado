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
 * buffer is converted to planar 16b floating point RGB. After step 8 is
 * completed, it is converted to chunky 16b floating point RGBX (64bpp).
 *
 *	1. Debayering of RAW data
 *	2. Demosaicing Bayer data
 *		a. Apply white balance
 *		b. Interpolate colour values for missing pixels
 *	3. Apply lens corrections (using LensFun library)
 *		a. Devignetting
 *		b. Geometry corrections (scaling, projection, distortion, chromatic
 *		abberations)
 *	4. vImage gamma correction
 *	5. vImage rotation/flip (to account for flipped status of image)
 *	6. vImage (de)convolution operations
 *	7. vImage 'morphological' operations
 *	8. vImage histogram operations (exposure, contrast, etc.)
 *	9. CoreImage filter pass
 *		a. Noise reduction, blurs
 *		b. Sharpening (luminance, unsharp mask)
 *		c. Colour adjustments and effects
 *		d. Distortion effects
 *		e. Geometry adjustments (crop, scaling, straightening, etc.)
 *		f. Vignetting and grain
 *	10. Generate final histogram (displayed in UI)
 *	11. Display transformations
 *		a. Convert to output (display/sRGB/Adobe RGB) colour space
 *		b. Convert to a different bitmap format
 *
 * The output of stage 5, and stage 10 are cached.
 *
 * Pipeline plugins can chose to process data at any major numbered
 * position in the pipeline. They are called _before_ the built-in pipeline
 * step.
 */

#import <Foundation/Foundation.h>

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
	
	TSRawPipelineStageGammaCorrection		= (4 << 16),
	TSRawPipelineStageRotationFlip			= (5 << 16),
	TSRawPipelineStageConvolution			= (6 << 16),
	TSRawPipelineStageMorphological			= (7 << 16),
	TSRawPipelineStageHistogramModification	= (8 << 16),
	
	TSRawPipelineStageCoreImageFilter		= (9 << 16),
	TSRawPipelineStageCINoiseReduceBlur		= (9 << 16) | 1,
	TSRawPipelineStageCISharpening			= (9 << 16) | 2,
	TSRawPipelineStageCIColourAdjustments	= (9 << 16) | 3,
	TSRawPipelineStageCIDistortionEffects	= (9 << 16) | 4,
	TSRawPipelineStageCIGeometryAdjustments	= (9 << 16) | 5,
	TSRawPipelineStageCIVignetteGrain		= (9 << 16) | 6,
	
	TSRawPipelineStageGenerateHistogram		= (10 << 16),
	TSRAWPipelineStageDisplayTransform		= (11 << 16)
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
   completionCallback:(nonnull TSRawPipelineCompletionCallback) complete
	 progressCallback:(nullable TSRawPipelineProgressCallback) progress
   conversionProgress:(NSProgress * _Nullable * _Nonnull) outProgress;

@end
