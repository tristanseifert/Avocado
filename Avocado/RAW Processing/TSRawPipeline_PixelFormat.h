//
//  TSRawPipeline_PixelFormat.h
//  Avocado
//
//	Specifies various functions that are used to convert between the different
//	pixel formats used by the RAW processing pipeline.
//
//	They exist primarily as wrappers around the relevant vImage functions.
//
//  Created by Tristan Seifert on 20160503.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#ifndef TSRawPipeline_PixelFormat_h
#define TSRawPipeline_PixelFormat_h

#import <Accelerate/Accelerate.h>

#import "TSRawPipeline_Types.h"

#pragma mark Initializers
/**
 * Sets up an instance of the conversion pipeline, with the given input data
 * and size.
 */
TSPixelConverterRef TSRawPipelineCreateConverter(void *inData, size_t inWidth, size_t inHeight);

/**
 * Destroys the given pixel conveter, deallocating any memory that was allocated
 * previously.
 */
void TSRawPipelineFreeConverter(TSPixelConverterRef converter);

#pragma mark Getters
/**
 * Returns a pointer to the original input data.
 *
 * @param converter Converter whose info to return.
 */
void *TSRawPipelineGetOriginalData(TSPixelConverterRef converter);

/**
 * Returns a pointer to the final RGBX data.
 *
 * @param converter Converter whose info to return.
 */
Pixel_FFFF *TSRawPipelineGetRGBXPointer(TSPixelConverterRef converter);

/**
 * Places the width and height in the given pointer variables.
 *
 * @param converter Converter from which to get the information.
 * @param outWidth Pointer to a variable to hold width, or NULL.
 * @param outHeight Pointer to a variable to hold height, or NULL.
 */
void TSRawPipelineGetSize(TSPixelConverterRef converter, NSUInteger *outWidth, NSUInteger *outHeight);

/**
 * Returns the vImage buffer for a given plane.
 *
 * @param converter Converter from which to get the information.
 * @param plane The numbered plane for which to get data, in the range [0..2].
 */
vImage_Buffer TSRawPipelineGetPlanevImageBufferBuffer(TSPixelConverterRef converter, NSUInteger plane);

#pragma mark Format Conversions
/**
 * Converts input RGB data (in RGB, 48bpp format, unsigned int) to a interleaved
 * floating point (out RGB, 96bpp) format.
 *
 * @param converter Converter object to use, containing the buffers into which
 * data is written.
 * @param maxValue Maximum value in the input pixel data. The floating point
 * buffer is normalized, such that this value corresponds to 1.0.
 *
 * @return YES if successful, NO otherwise.
 *
 * @note The output data will still be RGB format, but instead expanded to be
 * 32bit floating point per component.
 */
BOOL TSRawPipelineConvertRGB16UToFloat(TSPixelConverterRef converter, uint16_t maxValue);

/**
 * Converts the interlaced 96bpp floating point RGB data to three distinct
 * 32bit planes; one for each of the three colour components.
 *
 * @param converter Converter object whose planes should be converted.
 *
 * @return YES if successful, NO otherwise.
 *
 * @note This must be called after `TSRawPipelineConvertRGB16UToFloat` or the
 * results will be undefined.
 */
BOOL TSRawPipelineConvertRGBFFFToPlanarF(TSPixelConverterRef converter);

/**
 * Converts the the three 32bit floating point planes to a single interleaved
 * 128bpp RGBX buffer. In this case, X is fixed at 1.0.
 *
 * @param converter Converter object whose planes should be converted.
 *
 * @return YES if successful, NO otherwise.
 *
 * @note This must be called after the planes have been filled in with correct
 * data, such as after a call to `TSRawPipelineConvertRGBFFFToPlanarF;` the
 * output is otherwise undefined.
 */
BOOL TSRawPipelineConvertPlanarFToRGBXFFFF(TSPixelConverterRef converter);

#endif /* TSRawPipeline_PixelFormat_h */
