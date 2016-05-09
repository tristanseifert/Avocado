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

/**
 * Set to 1 to print out some additional debugging information, such as
 * conversion matrices and other variables.
 */
#define PRINT_DEBUG_INFO	0

// define some shorthands
/// size struct
#define S libRaw->sizes
/// color struct
#define C libRaw->color

#pragma mark Helpers
static void TSBuildGammaCurve(double pwr, double ts, int mode, int imax, uint16_t *curve, double *gamm);

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

#pragma mark Colour Scaling (White Balance)
/**
 * Inner colour scaling loop.
 */
static inline void TSRawScaleColourLoop(libraw_data_t *libRaw, uint16_t (*image)[4], float scale_mul[4]) {
	unsigned size = S.iheight * S.iwidth;
	
	if(C.cblack[4] && C.cblack[5]) {
		int val;
		
		for(size_t i = 0; i < size * 4; i++) {
			if (!(val = image[0][i])) continue;
			
			val -= C.cblack[6 + i/4 / S.iwidth % C.cblack[4] * C.cblack[5] + i/4 % S.iwidth % C.cblack[5]];
			val -= C.cblack[i & 3];
			val *= scale_mul[i & 3];
			image[0][i] = CLIP(val);
		}
	} else if(C.cblack[0] || C.cblack[1] || C.cblack[2] || C.cblack[3]) {
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
#if PRINT_DEBUG_INFO
		printf("Began median filter pass %i\n", pass);
#endif
		
		for (c = 0; c < 3; c += 2) {
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
		
#if PRINT_DEBUG_INFO
		printf("Completed median filter pass %i\n", pass);
#endif
	}
}

#pragma mark - Output
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
void TSRawConvertToRGB(libraw_data_t *libRaw, uint16_t (*image)[4], uint16_t (*outBuf)[3], int *histogram, uint16_t *gammaCurve) {
	size_t i, j, k;
	size_t row, col, c;
	uint16_t *img;
	uint16_t *outPtr;
	
	// fill the gamma array
	double gamm[6];
	
	// sRGB gamma
//	gamm[0] = (1.f / 2.2f);
//	gamm[1] = 12.92;
	// Adobe RGB gamma
//	gamm[0] = (1.f / 2.2f);
//	gamm[1] = 0.f;
	// ProPhoto gamma
	gamm[0] = (1.f / 1.8f);
	gamm[1] = 0.f;
	
	TSBuildGammaCurve(gamm[0], gamm[1], 0, 0, gammaCurve, gamm);
	
#if PRINT_DEBUG_INFO
	printf("gamm: \n");
	for(int i = 0; i < 6; i++) {
		printf("%5.5f ", gamm[i]);
	}
	printf("\n");
	
	printf("gamm (output): \n");
	for(int i = 0; i < 6; i++) {
		printf("%5.5f ", libRaw->params.gamm[i]);
	}
	printf("\n");
#endif
	
	// get some data from the struct
	ushort width = libRaw->sizes.width;
	ushort height = libRaw->sizes.height;
	
	// build the camera output profile
	float out[3], out_cam[3][4];
	
#if PRINT_DEBUG_INFO
	// print gamma curves
	printf("cam_xyz: \n");
	for(int y = 0; y < 4; y++) {
		for(int x = 0; x < 3; x++) {
			printf("%2.5f ", libRaw->color.cam_xyz[y][x]);
		}
		
		printf("\n");
	}
	
	printf("rgb_cam: \n");
	for(int y = 0; y < 4; y++) {
		for(int x = 0; x < 3; x++) {
			printf("%2.5f ", libRaw->color.rgb_cam[y][x]);
		}
		
		printf("\n");
	}
#endif
	
	// calculate the output camera matrix
	memcpy(out_cam, libRaw->color.rgb_cam, sizeof out_cam);
	
	for(i = 0; i < 3; i++) {
		for(j = 0; j < libRaw->idata.colors; j++) {
			for(out_cam[i][j] = k = 0; k < 3; k++) {
				out_cam[i][j] += prophoto_rgb[i][k] * libRaw->color.rgb_cam[k][j];
			}
		}
	}
	
	// set up for conversion to RGB
	img = image[0];
	
	memset(histogram, 0, sizeof(int) * 0x2000 * 4);
	
	for(row = 0; row < height; row++) {
		for(col = 0; col < width; col++, img += 4) {
			// perform conversion
			out[0] = out[1] = out[2] = 0;
			
			for(c = 0; c < libRaw->idata.colors; c++) {
				out[0] += out_cam[0][c] * img[c];
				out[1] += out_cam[1][c] * img[c];
				out[2] += out_cam[2][c] * img[c];
			}
			
			// write it back into the image buffer, as an integer value
			for(c = 0; c < 3; c++) {
				img[c] = CLIP((int) out[c]);
			}
			
			// update histogram
			for(c = 0; c < libRaw->idata.colors; c++) {
				histogram[(c * 0x2000) + (img[c] >> 3)]++;
			}
		}
	}
	
	// calculate gamma curve based off histogram? idk
	int perc, val, total, t_white = 0x2000;
	perc = S.width * S.height;
	
	for (t_white = c = 0; c < libRaw->idata.colors; c++) {
		for (val = 0x2000, total = 0; --val > 32;) {
			if ((total += histogram[(c * 0x2000) + val]) > perc) break;
			if (t_white < val) t_white = val;
		}
	}

#if PRINT_DEBUG_INFO
	printf("t_white = 0x%08x\n", t_white);
#endif
	TSBuildGammaCurve(gamm[0], gamm[1], 2, (t_white << 3), gammaCurve, gamm);
	
	// do gamma correction
	img = image[0];
	outPtr = outBuf[0];
	
	for(row = 0; row < height; row++) {
		for(col = 0; col < width; col++, img += 4, outPtr += 3) {
			for(c = 0; c < 3; c++) {
				// apply curve
				outPtr[c] = libRaw->color.curve[gammaCurve[img[c]]];
				//				outPtr[c] = libRaw->color.curve[img[c]];
			}
		}
	}
}

/**
 * Builds the gamma curve.
 */
static void TSBuildGammaCurve(double pwr, double ts, int mode, int imax, uint16_t *curve, double *gamm) {
#if PRINT_DEBUG_INFO
	printf("imax = %i\n", imax);
#endif
	
	int i;
	double g[6], bnd[2] = {0,0}, r;
	
	g[0] = pwr;
	g[1] = ts;
	g[2] = g[3] = g[4] = 0;
	bnd[g[1] >= 1] = 1;
	
	if (g[1] && (g[1] - 1) * (g[0] - 1) <= 0) {
		for (i = 0; i < 48; i++) {
			g[2] = (bnd[0] + bnd[1])/2;
			
			if (g[0]) {
				bnd[(pow(g[2]/g[1],-g[0]) - 1)/g[0] - 1/g[2] > -1] = g[2];
			} else {
				bnd[g[2]/exp(1-1/g[2]) < g[1]] = g[2];
			}
		}
		
		g[3] = g[2] / g[1];
		
		if (g[0]) {
			g[4] = g[2] * (1/g[0] - 1);
		}
	}
	
	if (g[0]) {
		g[5] = 1 / (g[1]*SQR(g[3])/2 - g[4]*(1 - g[3]) +
						  (1 - pow(g[3],1+g[0]))*(1 + g[4])/(1 + g[0])) - 1;
	} else {
		g[5] = 1 / (g[1]*SQR(g[3])/2 + 1
						  - g[2] - g[3] -	g[2]*g[3]*(log(g[3]) - 1)) - 1;
	}
		
	// no clue what the hell this is supposed to do
	if (!mode--) {
		memcpy(gamm, g, (sizeof(double) * 6));
		return;
	}
	
	// actually build the curve?
	for (i = 0; i < 0x10000; i++) {
		curve[i] = 0xffff;
		
		if ((r = (double) i / imax) < 1)
			curve[i] = 0x10000 * (mode
								  ? (r < g[3] ? r*g[1] : (g[0] ? pow( r,g[0])*(1+g[4])-g[4]    : log(r)*g[2]+1))
								  : (r < g[2] ? r/g[1] : (g[0] ? pow((r+g[4])/(1+g[4]),1/g[0]) : exp((r-1)/g[2]))));
	}
}