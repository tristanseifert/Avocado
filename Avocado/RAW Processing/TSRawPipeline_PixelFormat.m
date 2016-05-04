//
//  TSRawPipeline_PixelFormat.m
//  Avocado
//
//  Created by Tristan Seifert on 20160503.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <memory.h>

#import <Accelerate/Accelerate.h>

#import "TSRawPipeline_PixelFormat.h"
#import "TSRawPipeline_Types.h"

#pragma mark Format Conversions
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
BOOL TSRawPipelineConvertRGB16UToFloat(void *inBuf, size_t inWidth, size_t inHeight, uint16_t maxValue, void *outBuf) {
	vImage_Error error = kvImageNoError;
	vImage_Buffer vImageBufIn, vImageBufOut;
	
	// validate input values
	DDCAssert(inBuf != NULL, @"input buffer may not be NULL");
	DDCAssert(inWidth > 0, @"width may not be 0");
	DDCAssert(inHeight > 0, @"height may not be 0");
	DDCAssert(maxValue > 0, @"maximum value may not be 0");
	DDCAssert(outBuf != NULL, @"output buffer may not be NULL");
	
	// calculate the scale of input values
	float scale = 1 / ((float) maxValue);
	
	// create a vImage buffer for the input and output
	vImageBufIn = (vImage_Buffer) {
		.data = inBuf,
		.width = (inWidth * 3), // trick to convert each component
		.height = inHeight,
		.rowBytes = (inWidth * 3 * sizeof(uint16_t))
	};
	
	vImageBufOut = (vImage_Buffer) {
		.data = outBuf,
		.width = (inWidth * 3),
		.height = inHeight,
		.rowBytes = (inWidth * 3 * sizeof(Pixel_F))
	};
	
	// perform the conversion and check for errors
	error = vImageConvert_16UToF(&vImageBufIn, &vImageBufOut, 0, scale, kvImageNoFlags);
	
	if(error != kvImageNoError) {
		DDLogError(@"Error converting 16U -> Float: %li", error);
		return NO;
	}
	
	// successed
	return YES;
}

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
TSPlanarBufferRGB *TSRawPipelineConvertRGBFFFToPlanarF(void *inBuf, size_t inWidth, size_t inHeight) {
	vImage_Error error = kvImageNoError;
	
	// ensure input values are logical
	DDCAssert(inBuf != NULL, @"input buffer may not be NULL");
	DDCAssert(inWidth > 0, @"width may not be 0");
	DDCAssert(inHeight > 0, @"height may not be 0");
	
	// figure out bytes/line that's a multiple of 32 bytes, and size for the G/B planes
	size_t planarBytesPerRow = inWidth * sizeof(Pixel_F);
	
	if(planarBytesPerRow & 0x1F) {
		planarBytesPerRow += (0x20 - (planarBytesPerRow & 0x1F));
	}
	
	size_t planarBufSize = planarBytesPerRow * inHeight;
	
	// allocate planar output buffers for R/G/B
	Pixel_F *pGBuffer = valloc(planarBufSize);
	Pixel_F *pBBuffer = valloc(planarBufSize);
	
	/*
	 * Create vImage buffer descriptors for each of the planes with all the
	 * information previously discovered.
	 *
	 * Note that the red channel buffer utilizes the input buffer as its
	 * buffer pointer; this is no mistake. Even though the input buffer is thrice
	 * as large as it needs to be for this purpose, it saves the cost of yet
	 * another memory allocation, and saves quite a bit of memory.
	 */
	vImage_Buffer vImageBufR = {
		.data = inBuf,
		.rowBytes = planarBytesPerRow,
		.width = inWidth,
		.height = inHeight
	};
	
	vImage_Buffer vImageBufG = {
		.data = pGBuffer,
		.rowBytes = planarBytesPerRow,
		.width = inWidth,
		.height = inHeight
	};
	
	vImage_Buffer vImageBufB = {
		.data = pBBuffer,
		.rowBytes = planarBytesPerRow,
		.width = inWidth,
		.height = inHeight
	};
	
	// set up struct for input buffer
	vImage_Buffer vImageBufIn = {
		.data = inBuf,
		.width = inWidth,
		.height = inHeight,
		
		// there is no additional padding per line on the input buffer
		.rowBytes = (inWidth * 3)
	};
	
	// perform the conversion and check for errors
	error = vImageConvert_RGBFFFtoPlanarF(&vImageBufIn, &vImageBufR, &vImageBufG, &vImageBufB, kvImageNoFlags);
	
	if(error != kvImageNoError) {
		DDLogError(@"Error converting RGBFFF -> PlanarF: %li", error);
		return NULL;
	}
	
	// return the buffer
	TSPlanarBufferRGB *buffer = (TSPlanarBufferRGB *) calloc(1, sizeof(TSPlanarBufferRGB));
	
	buffer->components[0] = inBuf;
	buffer->components[1] = pGBuffer;
	buffer->components[2] = pBBuffer;
	
	buffer->componentsFree = (1 << 1) | (1 << 2);
	
	buffer->bytes_per_line = planarBytesPerRow;
	buffer->width = inWidth;
	buffer->height = inHeight;
	
	return buffer;
}

/**
 * Converts a planar 32bit floating point buffer to a 128bpp RGBX interleaved
 * buffer.
 *
 * @param buffer Input buffer to convert to RGBX. The input buffer will be
 * freed as part of this operation.
 *
 * @return An interleaved buffer structure with relevant information.
 */
TSInterleavedBufferRGBX *TSRawPipelineConvertPlanarFToRGBXFFFF(TSPlanarBufferRGB *inBuffer) {
	vImage_Error error = kvImageNoError;
	
	// ensure input values are logical
	DDCAssert(inBuffer != NULL, @"input buffer may not be NULL");
	
	// figure out bytes/line that's a multiple of 32 bytes, and the buffer size
	size_t chunkyBytesPerRow = inBuffer->width * sizeof(Pixel_FFFF);
	
	if(chunkyBytesPerRow & 0x1F) {
		chunkyBytesPerRow += (0x20 - (chunkyBytesPerRow & 0x1F));
	}
	
	size_t chunkyBufSize = chunkyBytesPerRow * inBuffer->height;
	
	// allocate memory for, and create a vImage buffer struct for the dest buffer
	Pixel_F *chunkyBuf = (Pixel_F *) valloc(chunkyBufSize);
	
	vImage_Buffer vImageBufDest = {
		.data = chunkyBuf,
		.rowBytes = chunkyBytesPerRow,
		.width = inBuffer->width,
		.height = inBuffer->height
	};
	
	// create vImage buffer structs for the input components
	vImage_Buffer vImageBufR = {
		.data = inBuffer->components[0],
		.rowBytes = inBuffer->bytes_per_line,
		.width = inBuffer->width,
		.height = inBuffer->height
	};
	
	vImage_Buffer vImageBufG = {
		.data = inBuffer->components[1],
		.rowBytes = inBuffer->bytes_per_line,
		.width = inBuffer->width,
		.height = inBuffer->height
	};
	
	vImage_Buffer vImageBufB = {
		.data = inBuffer->components[2],
		.rowBytes = inBuffer->bytes_per_line,
		.width = inBuffer->width,
		.height = inBuffer->height
	};
	
	// perform the conversion and check for errors
	error = vImageConvert_PlanarFToRGBXFFFF(&vImageBufR, &vImageBufG, &vImageBufB, 1.f, &vImageBufDest, kvImageNoFlags);
	
	if(error != kvImageNoError) {
		DDLogError(@"Error converting 3xPlanarF -> RGBX: %li", error);
		return NULL;
	}
	
	// free the input buffer
	TSFreePlanarBufferRGB(inBuffer);
	
	// create a buffer struct and populate it
	TSInterleavedBufferRGBX *buffer = (TSInterleavedBufferRGBX *) calloc(1, sizeof(TSInterleavedBufferRGBX));
	
	buffer->data = chunkyBuf;
	buffer->componentsFree = (1 << 0);
	
	buffer->bytes_per_line = chunkyBytesPerRow;
	buffer->width = inBuffer->width;
	buffer->height = inBuffer->height;
	
	return buffer;
}