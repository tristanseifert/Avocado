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

#import "TSRawPipeline_Types.h"

/**
 * Converts input RGB data (in RGB, 48bpp format, unsigned int) to a interleaved
 * floating point (out RGB, 96bpp) format.
 *
 * @param inBuf Input buffer, in RGB format.
 * @param inWidth Width of the image, in pixels.
 * @param inHeight Height of the image, in pixels.
 * @param maxValue Maximum value in the input pixel data. The floating point
 * buffer is normalized, such that this value corresponds to 1.0.
 * @param outBuf Output buffer, (inWidth * inHeight * 3 * sizeof(Pixel_F)) bytes
 * long at a minimum. Must be aligned to at least a 64 byte boundary; use of
 * valloc is reccomended.
 *
 * @return YES if successful, NO otherwise.
 *
 * @note The output data will still be RGB format, but instead expanded to be
 * 32bit floating point per component.
 */
BOOL TSRawPipelineConvertRGB16UToFloat(void *inBuf, size_t inWidth, size_t inHeight, uint16_t maxValue, void *outBuf);

/**
 * Takes a buffer of interleaved RGB data (RGB, 96bpp, 32-bit float) and splits
 * it into three planar arrays.
 *
 * @param inBuf A buffer that contains interleaved 96bpp data, such as the one
 * filled by TSRawPipelineConvertRGB16UToFloat. This buffer is re-used for one
 * of the planes.
 * @param inWidth Width of the image, in pixels.
 * @param inHeight Height of the image, in pixels.
 *
 * @return A pointer to a planar buffer struct if successful, NULL otherwise.
 */
TSPlanarBufferRGB *TSRawPipelineConvertRGBFFFToPlanarF(void *inBuf, size_t inWidth, size_t inHeight);

/**
 * Converts a planar 32bit floating point buffer to a 128bpp RGBX interleaved
 * buffer.
 *
 * @param buffer Input buffer to convert to RGBX. The input buffer will be
 * freed as part of this operation.
 *
 * @return An interleaved buffer structure with relevant information.
 */
TSInterleavedBufferRGBX *TSRawPipelineConvertPlanarFToRGBXFFFF(TSPlanarBufferRGB *inBuffer);

#endif /* TSRawPipeline_PixelFormat_h */
