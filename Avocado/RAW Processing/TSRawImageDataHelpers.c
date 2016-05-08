//
//  TSRawImageDataHelpers.c
//  Avocado
//
//  Created by Tristan Seifert on 20160506.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#include "TSRawImageDataHelpers.h"
#include "interpolation_shared.h"

#include <float.h>
#include <string.h>
#include <memory.h>
#include <stdlib.h>
#include <math.h>

// define some shorthands

/// size struct
#define S libRaw->sizes
/// color struct
#define C libRaw->color

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
				val -= cblack[cc];
				
				// if it's higher than the existing max, store it
				if(val > ldmax) {
					ldmax = val;
				}
			} else {
				// it's below the black level, so force it to zero
				val = 0;
			}
			
			// store the pixel value
			outBuf[(row * S.iwidth) + col][cc] = val;
		}
		
		// store the highest pixel value
		if(*dmaxp < ldmax)
			*dmaxp = ldmax;
	}
}

#pragma mark Black Level
/**
 * Adjusts the black level of the image.
 *
 * This corresponds to LibRaw::adjust_bl().
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 */
void TSRawAdjustBlackLevel(libraw_data_t *libRaw, uint16_t (*image)[4]) {
	int c;
	
	// Add common part to cblack[] early
	if (libRaw->idata.filters > 1000 && (C.cblack[4] + 1) / 2 == 1 && (C.cblack[5] + 1) / 2 == 1) {
		for(c = 0; c < 4; c++){
			C.cblack[c] += C.cblack[6 + c/2 % C.cblack[4] * C.cblack[5] + c%2 % C.cblack[5]];
		}
		
		C.cblack[4] = C.cblack[5] = 0;
	}
	// Fuji RAF dng
	else if(libRaw->idata.filters <= 1000 && C.cblack[4] == 1 && C.cblack[5] == 1) {
		for(c = 0; c < 4; c++) {
			C.cblack[c] += C.cblack[6];
		}
		
		C.cblack[4] = C.cblack[5]=0;
	}
	
	// remove common part from C.cblack[]
	int i = C.cblack[3];
	for(c = 0; c < 3; c++) {
		if (i > C.cblack[c]) {
			i = C.cblack[c];
		}
	}
	
	// remove common part
	for(c = 0; c < 4; c++) {
		C.cblack[c] -= i;
	}
	C.black += i;
	
	// Now calculate common part for cblack[6+] part and move it to C.black
	if(C.cblack[4] && C.cblack[5]) {
		i = C.cblack[6];
		for(c = 1; c < (C.cblack[4] * C.cblack[5]); c++) {
			if(i > C.cblack[6+c]) {
				i = C.cblack[6+c];
			}
		}
	
		// Remove i from cblack[6+]
		int nonz = 0;
		
		for(c = 0; c < (C.cblack[4] * C.cblack[5]); c++) {
			C.cblack[6+c]-=i;
			
			if(C.cblack[6+c]) {
				nonz++;
			}
		}
		
		C.black +=i;
		if(!nonz) {
			C.cblack[4] = C.cblack[5] = 0;
		}
	}
	
	for(c = 0; c < 4; c++) {
		C.cblack[c] += C.black;
	}
}

/**
 * Subtracts black to bring the image's black level into whack.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 */
void TSRawSubtractBlack(libraw_data_t *libRaw, uint16_t (*image)[4]) {
	if((C.cblack[0] || C.cblack[1] || C.cblack[2] || C.cblack[3] || (C.cblack[4] && C.cblack[5]) )) {
#define BAYERC(row,col,c) imgdata.image[((row) >> IO.shrink)*S.iwidth + ((col) >> IO.shrink)][c]
		int cblk[4], i;
		for(i = 0; i < 4; i++)
			cblk[i] = C.cblack[i];
		
		int size = S.iheight * S.iwidth;
		
		int dmax = 0;
		if(C.cblack[4] && C.cblack[5]) {
			for(i = 0; i< (size * 4); i++) {
				int val = image[0][i];
				
				val -= C.cblack[6 + i/4 / S.iwidth % C.cblack[4] * C.cblack[5] +
								i/4 % S.iwidth % C.cblack[5]];
				val -= cblk[i & 3];
				
				image[0][i] = CLIP(val);
				if(dmax < val) dmax = val;
			}
		} else {
			for(i = 0; i < (size * 4); i++) {
				int val = image[0][i];
				val -= cblk[i & 3];
				image[0][i] = CLIP(val);
				if(dmax < val) dmax = val;
			}
		}
		
		C.data_maximum = dmax & 0xffff;
		C.maximum -= C.black;
		
		// clear the values to zero
		memset(&C.cblack, 0, sizeof(C.cblack));
		C.black = 0;
		
#undef BAYERC
	} else {
		// Nothing to do, maximum is already calculated, black level is 0, so no change
		// only calculate channel maximum;
		int idx;
		ushort *p = (ushort*) image;
		int dmax = 0;
		
		for(idx=0; idx < (S.iheight * S.iwidth * 4); idx++) {
			if(dmax < p[idx]) dmax = p[idx];
		}
		
		C.data_maximum = dmax;
	}
}

#pragma mark - Pre-Interpolation
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

#pragma mark Colour Scaling
/**
 * Inner colour scaling loop.
 */
static inline void TSRawScaleColourLoop(libraw_data_t *libRaw, uint16_t (*image)[4], float scale_mul[4]) {
	unsigned size = S.iheight * S.iwidth;
	
	if(C.cblack[4] && C.cblack[5]) {
		int val;
		for(unsigned i=0; i < size*4; i++) {
			if (!(val = image[0][i])) continue;
			val -= C.cblack[6 + i/4 / S.iwidth % C.cblack[4] * C.cblack[5] +
							i/4 % S.iwidth % C.cblack[5]];
			val -= C.cblack[i & 3];
			val *= scale_mul[i & 3];
			image[0][i] = CLIP(val);
		}
	} else if(C.cblack[0]||C.cblack[1]||C.cblack[2]||C.cblack[3]) {
		for(size_t i=0; i < size*4; i++) {
			int val = image[0][i];
			if (!val) continue;
			val -= C.cblack[i & 3];
			val *= scale_mul[i & 3];
			image[0][i] = CLIP(val);
		}
	} else { // BL is zero
		for(size_t i=0; i < size*4; i++) {
			int val = image[0][i];
			val *= scale_mul[i & 3];
			image[0][i] = CLIP(val);
		}
	}
}

/**
 * Applies contrast and scaling to colour data; this applies white balance.
 *
 * @note This corresponds to scale_colors() in LibRaw.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 */
void TSRawPreInterpolationApplyWB(libraw_data_t *libRaw, uint16_t (*image)[4]) {
	unsigned int row, col, c, sum[8];
	int val, dark, sat;
	double dmin, dmax;
	float scale_mul[4];
	
	// get some data from the struct
	unsigned int filters = libRaw->idata.filters;
	
	// copy user multipliers, if existent
#if 0
	if(user_white_balance) {
		memcpy(libRaw->color.pre_mul, NULL, sizeof libRaw->color.pre_mul);
	}
#endif
	
	if (/*use_camera_wb &&*/ libRaw->color.cam_mul[0] != -1) {
		memset (sum, 0, sizeof sum);
		for (row=0; row < 8; row++)
			for (col=0; col < 8; col++) {
				c = FC(row, col, filters);
				
				if ((val = libRaw->color.white[row][col] - libRaw->color.cblack[c]) > 0)
					sum[c] += val;
				sum[c+4]++;
			}
		
			if(sum[0] && sum[1] && sum[2] && sum[3]) {
				FORC4 libRaw->color.pre_mul[c] = (float) sum[c+4] / sum[c];
			} else if(libRaw->color.cam_mul[0] && libRaw->color.cam_mul[2]) {
				memcpy(libRaw->color.pre_mul, libRaw->color.cam_mul, sizeof libRaw->color.pre_mul);
			} else {
				// bad white balance
			}
	}
	
	if (libRaw->color.pre_mul[1] == 0) libRaw->color.pre_mul[1] = 1;
	if (libRaw->color.pre_mul[3] == 0) libRaw->color.pre_mul[3] = libRaw->idata.colors < 4 ? libRaw->color.pre_mul[1] : 1;
	
	dark = libRaw->color.black;
	sat = libRaw->color.maximum;
	
	libRaw->color.maximum -= libRaw->color.black;
	
	for(dmin = DBL_MAX, dmax=c=0; c < 4; c++) {
		if (dmin > libRaw->color.pre_mul[c])
			dmin = libRaw->color.pre_mul[c];
		if (dmax < libRaw->color.pre_mul[c])
			dmax = libRaw->color.pre_mul[c];
	}
	
	dmax = dmin;
	FORC4 scale_mul[c] = (libRaw->color.pre_mul[c] /= dmax) * 65535.0 / libRaw->color.maximum;
	
	if (filters > 1000 && (libRaw->color.cblack[4]+1)/2 == 1 && (libRaw->color.cblack[5]+1)/2 == 1) {
		FORC4 libRaw->color.cblack[FC(c/2,c%2, filters)] += libRaw->color.cblack[6 + c/2 % libRaw->color.cblack[4] * libRaw->color.cblack[5] + c%2 % libRaw->color.cblack[5]];
		libRaw->color.cblack[4] = libRaw->color.cblack[5] = 0;
	}
	
	// perform the scaling loop
	TSRawScaleColourLoop(libRaw, image, scale_mul);
}

#pragma mark - Post-interpolation
/**
 * Performs post-interpolation green channel mixing.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 */
void TSRawPostInterpolationMixGreen(libraw_data_t *libRaw, uint16_t (*image)[4]) {
	int i;
	
	// we're now down to three colours
	libRaw->idata.colors = 3;
	
	// average green channels
	for(i = 0; i < (S.height * S.width); i++) {
		image[i][1] = image[i][3] = (image[i][1] + image[i][3]) / 2;
	}
}

/**
 * Performs a median filter on the image to remove any anomalies.
 *
 * @param libRaw LibRaw instance from which to acquire some image info
 * @param image Image buffer
 * @param med_passes How many passes of the median filter to go through.
 */
void TSRawPostInterpolationMedianFilter(libraw_data_t *libRaw, uint16_t (*image)[4], int med_passes) {
	ushort (*pix)[4];
	int pass, c, i, j, k, med[9];
	
	// get some data from the struct
	ushort width = libRaw->sizes.width;
	ushort height = libRaw->sizes.height;
	
	static const uchar opt[] =	/* Optimal 9-element median search */
	{ 1,2, 4,5, 7,8, 0,1, 3,4, 6,7, 1,2, 4,5, 7,8,
		0,3, 5,8, 4,7, 3,6, 1,4, 2,5, 4,7, 4,2, 6,4, 4,2 };
	
	for (pass=1; pass <= med_passes; pass++) {
		printf("Began median filter pass %i\n", pass);
		
		for (c=0; c < 3; c+=2) {
			for (pix = image; pix < image+width*height; pix++)
				pix[0][3] = pix[0][c];
			for (pix = image+width; pix < image+width*(height-1); pix++) {
				if ((pix-image+1) % width < 2) continue;
				for (k=0, i = -width; i <= width; i += width)
					for (j = i-1; j <= i+1; j++)
						med[k++] = pix[j][3] - pix[j][1];
				for (i=0; i < sizeof opt; i+=2)
					if     (med[opt[i]] > med[opt[i+1]])
						SWAP (med[opt[i]] , med[opt[i+1]]);
				pix[0][c] = CLIP(med[4] + pix[0][1]);
			}
		}
		
		printf("Completed median filter pass %i\n", pass);
	}
}

#pragma mark - Output
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
	
	float gamma_exp = 1.f / 2.4f; // default gamma of 2.4
	
	// build the camera output profile
	float out[3], out_cam[3][4];
	
	memcpy(out_cam, libRaw->color.rgb_cam, sizeof out_cam);
	
	for(i = 0; i < 3; i++) {
		for(j=0; j < libRaw->idata.colors; j++) {
			for(out_cam[i][j] = k=0; k < 3; k++) {
				out_cam[i][j] += out_rgb[0][i][k] * libRaw->color.rgb_cam[k][j];
			}
		}
	}
	
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
			}
		}
	}
}