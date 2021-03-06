//
//  TSPixelFormatConverter.h
//  Avocado
//
//	Specifies various functions that are used to convert between the different
//	pixel formats used by the RAW processing pipeline.
//
//	They exist primarily as wrappers around the relevant vImage functions.
//
//	NOTE: This class is not thread safe. While one instance may be used from
//	different threads, the caller is responsible for ensuring that only a single
//	thread is using the converter at a time, since it contains pointers to
//	memory buffers that the functions will mutate.
//
//  Created by Tristan Seifert on 20160503.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#ifndef TSRawPipeline_PixelFormat_h
#define TSRawPipeline_PixelFormat_h

#import <Accelerate/Accelerate.h>

#ifdef __cplusplus
extern "C" {
#endif

#pragma mark Types
/**
 * Opaque type defining all data that the pixel conversion routines need to
 * properly operate, including pointers to memory.
 */
typedef struct TSPixelConverter* TSPixelConverterRef;

#pragma mark Initializers
/**
 * Sets up an instance of the conversion pipeline, with the given input data
 * and size.
 */
TSPixelConverterRef TSPixelConverterCreate(void *inData, NSUInteger inWidth, NSUInteger inHeight);

/**
 * Destroys the given pixel conveter, deallocating any memory that was allocated
 * previously.
 */
void TSPixelConverterFree(TSPixelConverterRef converter);

/**
 * Resizes the pixel converter to the given size. The old memory will be de-
 * allocated, and new buffers are allocated. No data is copied.
 */
void TSPixelConverterResize(TSPixelConverterRef converter, NSUInteger newWidth, NSUInteger newHeight);

#pragma mark Getters
/**
 * Returns a pointer to the original input data.
 *
 * @param converter Converter whose info to return.
 */
void *TSPixelConverterGetOriginalData(TSPixelConverterRef converter);

/**
 * Returns a pointer to the final RGBX data.
 *
 * @param converter Converter whose info to return.
 */
Pixel_FFFF *TSPixelConverterGetRGBXPointer(TSPixelConverterRef converter);

/**
 * Returns the stride (bytes / row) of the output buffer.
 *
 * @param Converter whose info to return.
 */
size_t TSPixelConverterGetRGBXStride(TSPixelConverterRef converter);

/**
 * Places the width and height in the given pointer variables.
 *
 * @param converter Converter from which to get the information.
 * @param outWidth Pointer to a variable to hold width, or NULL.
 * @param outHeight Pointer to a variable to hold height, or NULL.
 */
void TSPixelConverterGetSize(TSPixelConverterRef converter, NSUInteger *outWidth, NSUInteger *outHeight);

/**
 * Returns the vImage buffer for a given plane.
 *
 * @param converter Converter from which to get the information.
 * @param plane The numbered plane for which to get data, in the range [0..2].
 */
vImage_Buffer TSPixelConverterGetPlanevImageBufferBuffer(TSPixelConverterRef converter, NSUInteger plane);

#pragma mark Setters
/**
 * Sets the RGB data input buffer.
 *
 * @param converter Converter whose input buffer to set.
 * @param inData Input data buffer.
 */
void TSPixelConverterSetInData(TSPixelConverterRef converter, void *inData);

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
BOOL TSPixelConverterRGB16UToFloat(TSPixelConverterRef converter, uint16_t maxValue);

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
BOOL TSPixelConverterRGBFFFToPlanarF(TSPixelConverterRef converter);

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
BOOL TSPixelConverterPlanarFToRGBXFFFF(TSPixelConverterRef converter);

#pragma mark Geometric Operations
/**
 * Rotates the image by the given multiple of 90 degrees. 0 is no rotation, 1 is
 * 90° counter-clockwise, and so forth.
 *
 * @param converter Converter object whose planes should be rotated.
 * @param rotation Rotation, multiple of 90°.
 *
 * @return YES if successful, NO otherwise.
 */
BOOL TSPixelConverterRotate90(TSPixelConverterRef converter, ssize_t rotation);

#pragma mark Histogram Operations
/**
 * Stretches the contrast of the image, such that all values between the
 * minimum and maximum points are linearly stretched and distributed evenly.
 *
 * @param converter Converter object whose planes should be adjusted.
 * @param min Minimum bound for the contrast stretch.
 * @param max Maximum bound for the contrast stretch.
 */
BOOL TSPixelConverterContrastStretch(TSPixelConverterRef converter, Pixel_F min, Pixel_F max);

#ifdef __cplusplus
}
#endif

#endif /* TSRawPipeline_PixelFormat_h */
