//
//  TSRawImageDataHelpers.h
//  Avocado
//
//  Created by Tristan Seifert on 20160506.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#ifndef TSRawImageDataHelpers_h
#define TSRawImageDataHelpers_h

#include <stdint.h>

#include "libraw.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Copies single component Bayer data from the given LibRaw instance into the
 * given output buffer.
 *
 * @param libRaw LibRaw instance from which to copy data
 * @param cblack Black levels for each component
 * @param dmaxp Pointer to a variable in which to store the maximum pixel value.
 * @param outBuf Output buffer; this should be a 16-bit, four component buffer.
 */
void TSRawCopyBayerData(libraw_data_t *libRaw, unsigned short cblack[4], unsigned short *dmaxp, uint16_t (*outBuf)[4]);

/**
 * Adjusts the black level of the image.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 */
void TSRawAdjustBlackLevel(libraw_data_t *libRaw, uint16_t (*image)[4]);

/**
 * Subtracts black to bring the image's black level into whack.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 */
void TSRawSubtractBlack(libraw_data_t *libRaw, uint16_t (*image)[4]);

/**
 * Performs pre-interpolation tasks on the colour data.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 */
void TSRawPreInterpolation(libraw_data_t *libRaw, uint16_t (*image)[4]);

/**
 * Applies contrast and scaling to colour data; this applies white balance.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 */
void TSRawPreInterpolationApplyWB(libraw_data_t *libRaw, uint16_t (*image)[4]);

/**
 * Performs post-interpolation green channel mixing.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 */
void TSRawPostInterpolationMixGreen(libraw_data_t *libRaw, uint16_t (*image)[4]);

/**
 * Performs a median filter on the image to remove any anomalies.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 * @param med_passes How many passes of the median filter to go through. A good
 * default value is 3.
 */
void TSRawPostInterpolationMedianFilter(libraw_data_t *libRaw, uint16_t (*image)[4], int med_passes);

/**
 * Converts the output data to RGB format. This should be run after
 * interpolation.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer (after interpolation)
 * @param outBuf Output data buffer
 * @param histogram Pointer to the histogram to be created. Has 0x2000 bins,
 * times four for four possible colours.
 * @param gammaCurve Gamma curve buffer
 */
void TSRawConvertToRGB(libraw_data_t *libRaw, uint16_t (*image)[4], uint16_t (*outBuf)[3], int *histogram, uint16_t *gammaCurve);

/**
 * Uses bilinear interpolation to interpolate the value of a single component at
 * a fractional coordinate. The component is assumed to be at position 0 of the
 * input pointer.
 *
 * @param buffer Input buffer on which to interpolate.
 * @param stride Number of elements (for example, width * 3) per row.
 * @param x Floating point X coordinate
 * @param y Floating point Y coordinate
 *
 * @return The value of the component, as interpolated.
 */
uint16_t TSInterpolatePixelBilinear(uint16_t *buffer, size_t stride, float x, float y);

#ifdef __cplusplus
}
#endif
	
#endif /* TSRawImageDataHelpers_h */
