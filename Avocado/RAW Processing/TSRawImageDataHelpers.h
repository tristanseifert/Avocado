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
 * Performs pre-interpolation tasks on the colour data.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 */
void TSRawPreInterpolation(libraw_data_t *libRaw, uint16_t (*image)[4]);

/**
 * Converts the output data to RGB format. This should be run after
 * interpolation.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer (after interpolation)
 * @param outBuf Output data buffer
 */
void TSRawConvertToRGB(libraw_data_t *libRaw, uint16_t (*image)[4], uint16_t (*outBuf)[3]);

#endif /* TSRawImageDataHelpers_h */
