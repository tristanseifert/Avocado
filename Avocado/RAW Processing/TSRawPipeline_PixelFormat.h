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
 * Converts the RGB data produced by demosaicing of Bayer data and lens
 * corrections to planar 16bit floating point.
 */
TSPlanarBufferRGB TSRawPipelineConvertRGB16UToPlanar16U(void *inBuf, size_t inWidth, size_t inHeight);

/**
 * Converts a planar 16bit unsigned integer buffer to 16bit floating point,
 * normalizing pixel values in the range of [0..1].
 *
 * @param inBuffer Planar buffer structure to operate on. Buffers are modified
 * in place.
 * @param maxValue Maximum value in the buffer; used to normalize numbers.
 */
void TSRawPipelineConvertPlanar16UToFloatingPoint(TSPlanarBufferRGB *inBuffer, uint16_t maxValue);

/**
 * Converts a planar 16bit floating point buffer to a 64bpp RGBX interleaved
 * buffer.
 *
 * @param inBuffer Input buffer to convert.
 *
 * @return An interleaved buffer structure with relevant information.
 */
TSInterleavedBufferRGBX TSRawPipelineConvertPlanarFToRGBXFFFF(TSPlanarBufferRGB *inBuffer);

#endif /* TSRawPipeline_PixelFormat_h */
