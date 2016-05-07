//
//  TSRawImageDataHelpers.c
//  Avocado
//
//  Created by Tristan Seifert on 20160506.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#include "TSRawImageDataHelpers.h"

#include <string.h>
#include <memory.h>
#include <stdlib.h>
#include <math.h>

// define some shorthands

/// size struct
#define S libRaw->sizes

#pragma mark Helpers

#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define LIM(x,min,max) MAX(min,MIN(x,max))
#define CLIP(x) LIM((int)(x),0,65535)

#define FC(row, col, filters) \
(filters >> ((((row) << 1 & 14) + ((col) & 1)) << 1) & 3)

/**
 * I honestly have no fucking clue what this does but it seems required
 */
static inline int fcol(size_t row, size_t col, unsigned int filters, ushort top_margin, ushort left_margin) {
	static const char filter[16][16] = {
		{ 2,1,1,3,2,3,2,0,3,2,3,0,1,2,1,0 },
		{ 0,3,0,2,0,1,3,1,0,1,1,2,0,3,3,2 },
		{ 2,3,3,2,3,1,1,3,3,1,2,1,2,0,0,3 },
		{ 0,1,0,1,0,2,0,2,2,0,3,0,1,3,2,1 },
		{ 3,1,1,2,0,1,0,2,1,3,1,3,0,1,3,0 },
		{ 2,0,0,3,3,2,3,1,2,0,2,0,3,2,2,1 },
		{ 2,3,3,1,2,1,2,1,2,1,1,2,3,0,0,1 },
		{ 1,0,0,2,3,0,0,3,0,3,0,3,2,1,2,3 },
		{ 2,3,3,1,1,2,1,0,3,2,3,0,2,3,1,3 },
		{ 1,0,2,0,3,0,3,2,0,1,1,2,0,1,0,2 },
		{ 0,1,1,3,3,2,2,1,1,3,3,0,2,1,3,2 },
		{ 2,3,2,0,0,1,3,0,2,0,1,2,3,0,1,0 },
		{ 1,3,1,2,3,2,3,2,0,2,0,1,1,0,3,0 },
		{ 0,2,0,3,1,0,0,1,1,3,3,2,3,2,2,1 },
		{ 2,1,3,2,3,1,2,1,0,3,0,2,0,2,0,2 },
		{ 0,3,1,0,0,2,0,3,2,1,3,1,1,3,1,3 }
	};
	
	if (filters == 1) return filter[(row + top_margin) & 15][(col + left_margin) & 15];

	// cut out support for Fuji X-Trans sensors for now
//	if (filters == 9) return xtrans[(row+6) % 6][(col+6) % 6];
	return FC(row, col, filters);
}

/**
 * Applies the gamma correction on the given value.
 */
static inline uint16_t TSRawApplyGamma(float value, float exp) {
	value /= 65535;
	
	// Exact sRGB gamma
	if (value <= 0.0031308) {
		return (uint16_t) CLIP(846712.2 * value);
	} else {
		return (uint16_t) CLIP(65535*(1.055*pow(value,exp)-0.055));
	}
}

#pragma mark Conversion and Copying
/**
 * Copies single component Bayer data from the given LibRaw instance into the
 * given output buffer.
 *
 * @param libRaw LibRaw instance from which to copy data
 * @param cblack Black levels for each component
 * @param dmaxp Pointer to a variable in which to store the maximum pixel value.
 * @param outBuf Output buffer; this should be a 16-bit, four component buffer.
 */
void TSRawCopyBayerData(libraw_data_t *libRaw, unsigned short cblack[4], unsigned short *dmaxp, uint16_t (*outBuf)[4]) {
	size_t row;
	
	// get some caches
	unsigned int filters = libRaw->idata.filters;
	ushort top_margin = S.top_margin;
	ushort left_margin = S.left_margin;
	
	// iterate through every pixel
	for (row = 0; row < S.height; row++) {
		size_t col;
		unsigned short ldmax = 0;
		
		for (col = 0; col < S.width; col++) {
			ushort val = libRaw->rawdata.raw_image[(row + S.top_margin) * S.raw_pitch/2 + (col + S.left_margin)];
			int cc = fcol(row, col, filters, top_margin, left_margin);
			
			// adjust black levels
			if(val > cblack[cc]) {
				// subtract black level
//				val -= cblack[cc];
				
				// if it's higher than the existing max, store it
				if(val > ldmax) {
					ldmax = val;
				}
			} else {
				// it's below the black level, so force it to zero
				val = 0;
			}
			
			// excrete the pixel value
			outBuf[(row * S.iwidth) + col][cc] = val;
//			outBuf[(row * S.iwidth) + col][3] = 0xFFFF; // TEST: Force alpha to max
		}
		
		// store the highest pixel value
		if(*dmaxp < ldmax)
			*dmaxp = ldmax;
	}
}

/**
 * Performs pre-interpolation tasks on the colour data.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 */
void TSRawPreInterpolation(libraw_data_t *libRaw, uint16_t (*image)[4]) {
	size_t row, col;
	
	// get some data from the struct
	ushort width = libRaw->sizes.width;
	ushort height = libRaw->sizes.height;
	
	unsigned int filters = libRaw->idata.filters;
	
	// if there's filters and three colours…
	if(libRaw->idata.filters && libRaw->idata.colors == 3) {
		for (row = FC(1, 0, filters) >> 1; row < height; row+=2)
			for (col = FC(row, 1, filters) & 1; col < width; col+=2)
				image[row*width+col][1] = image[row*width+col][3];
		
		libRaw->idata.filters &= ~((libRaw->idata.filters & 0x55555555) << 1);
	}
}

/**
 * Converts the output data to RGB format. This should be run after 
 * interpolation.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer (after interpolation)
 * @param outBuf Output data buffer
 */
void TSRawConvertToRGB(libraw_data_t *libRaw, uint16_t (*image)[4], uint16_t (*outBuf)[3]) {
	size_t i, j, k;
	size_t row, col, c;
	uint16_t *img;
	uint16_t *outPtr;
	
	// colour profile data (shamelessly stolen from dcraw.c)
	static const double xyzd50_srgb[3][3] =
	{ { 0.436083, 0.385083, 0.143055 },
		{ 0.222507, 0.716888, 0.060608 },
		{ 0.013930, 0.097097, 0.714022 } };
	static const double rgb_rgb[3][3] =
	{ { 1,0,0 }, { 0,1,0 }, { 0,0,1 } };
	static const double adobe_rgb[3][3] =
	{ { 0.715146, 0.284856, 0.000000 },
		{ 0.000000, 1.000000, 0.000000 },
		{ 0.000000, 0.041166, 0.958839 } };
	static const double wide_rgb[3][3] =
	{ { 0.593087, 0.404710, 0.002206 },
		{ 0.095413, 0.843149, 0.061439 },
		{ 0.011621, 0.069091, 0.919288 } };
	static const double prophoto_rgb[3][3] =
	{ { 0.529317, 0.330092, 0.140588 },
		{ 0.098368, 0.873465, 0.028169 },
		{ 0.016879, 0.117663, 0.865457 } };
	static const double (*out_rgb[])[3] =
	{ rgb_rgb, adobe_rgb, wide_rgb, prophoto_rgb };
	
	float gamma_exp = 1.f / 2.4; // default gamma of 2.4
	
	// build the camera output profile
	float out[3], out_cam[3][4];
	
	memcpy(out_cam, libRaw->color.rgb_cam, sizeof out_cam);
	
	for (i=0; i < 3; i++)
		for (j=0; j < libRaw->idata.colors; j++)
			for (out_cam[i][j] = k=0; k < 3; k++)
				out_cam[i][j] += out_rgb[1][i][k] * libRaw->color.rgb_cam[k][j];
	
	// get some data from the struct
	ushort width = libRaw->sizes.width;
	ushort height = libRaw->sizes.height;
	
	// set up for colour space conversion
	img = image[0];
	outPtr = outBuf[0];
	
	// iterate through each pixel
	for(row = 0; row < height; row++) {
		for(col = 0; col < width; col++, img += 4, outPtr += 3) {
			// perform profile conversion
			out[0] = out[1] = out[2] = 0;
			
			for(c = 0; c < libRaw->idata.colors; c++) {
				out[0] += out_cam[0][c] * img[c];
				out[1] += out_cam[1][c] * img[c];
				out[2] += out_cam[2][c] * img[c];
			}
			
			// apply gamma correction and save to output
			for(c = 0; c < 3; c++) {
				outPtr[c] = TSRawApplyGamma(out[c], gamma_exp);
//				outPtr[c] = img[c] << 2;
			}
		}
	}
}