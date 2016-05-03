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
 * Converts the RGB data produced by demosaicing of Bayer data and lens
 * corrections to planar 16bit floating point.
 */
TSPlanarBufferRGB TSRawPipelineConvertRGB16UToPlanar16U(void *inBuf, size_t inWidth, size_t inHeight) {
	vImage_Error error = kvImageNoError;
	
	// figure out bytes/line that's a multiple of 32 bytes, and the buffer size
	size_t planarBytesPerRow = inWidth * sizeof(Pixel_F);
	
	if(planarBytesPerRow & 0x1F) {
		planarBytesPerRow += (0x20 - (planarBytesPerRow & 0x1F));
	}
	
	size_t planarBufSize = planarBytesPerRow * inHeight;
	
	// allocate planar output buffers for R/G/B
	Pixel_F *pRBuffer = valloc(planarBufSize);
	Pixel_F *pGBuffer = valloc(planarBufSize);
	Pixel_F *pBBuffer = valloc(planarBufSize);
	
	// create structs for each of the planar buffers
	vImage_Buffer vImageBufR = {
		.data = pRBuffer,
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
		
		// assume there is no additional padding
		.rowBytes = (inWidth * 3)
	};
	
	// perform the conversion and check for errors
	error = vImageConvert_RGBFFFtoPlanarF(&vImageBufIn, &vImageBufR, &vImageBufG, &vImageBufB, kvImageNoFlags);
	
	DDCAssert(error == kvImageNoError, @"Error converting RGBFFF -> PlanarF: %li", error);
	
	// return the buffers
	return (TSPlanarBufferRGB) {
		// the order of components is RGB
		.components = {pRBuffer, pGBuffer, pBBuffer},
		
		.bytes_per_line = planarBytesPerRow,
		.width = inWidth,
		.height = inHeight
	};
}

/**
 * Converts a planar 16 bit unsigned integer buffer to 16bit floating point,
 * normalizing pixel values in the range of [0..1].
 *
 * @param buffer Planar buffer structure to operate on. Buffers are modified
 * in place.
 * @param maxValue Maximum value in the buffer; used to normalize numbers.
 */
void TSRawPipelineConvertPlanar16UToFloatingPoint(TSPlanarBufferRGB *inBuffer, uint16_t maxValue) {
	vImage_Error error = kvImageNoError;
	vImage_Buffer vImageBuf;
	
	// calculate the scale of input values
	float scale = 1 / ((float) maxValue);
	
	// perform the same operation on all three components
	for(NSUInteger i = 0; i < 3; i++) {
		// create a vImage buffer for the input
		vImageBuf = (vImage_Buffer) {
			.data = inBuffer->components[0],
			.width = inBuffer->width,
			.height = inBuffer->height,
			
			// assume there is no additional padding
			.rowBytes = inBuffer->bytes_per_line
		};
		
		// perform the conversion and check for errors
		error = vImageConvert_16UToF(&vImageBuf, &vImageBuf, 0, scale, kvImageNoFlags);
		
		DDCAssert(error == kvImageNoError, @"Error converting 16U -> Float: %li", error);
	}
	
	// there's nothing else that we need to do
}

/**
 * Converts a planar 16bit floating point buffer to a 64bpp RGBX interleaved
 * buffer.
 *
 * @param buffer Input buffer to convert.
 *
 * @return An interleaved buffer structure with relevant information.
 */
TSInterleavedBufferRGBX TSRawPipelineConvertPlanarFToRGBXFFFF(TSPlanarBufferRGB *inBuffer) {
	vImage_Error error = kvImageNoError;
	
	// figure out bytes/line that's a multiple of 32 bytes, and the buffer size
	size_t chunkyBytesPerRow = inBuffer->width * sizeof(Pixel_FFFF);
	
	if(chunkyBytesPerRow & 0x1F) {
		chunkyBytesPerRow += (0x20 - (chunkyBytesPerRow & 0x1F));
	}
	
	size_t chunkyBufSize = chunkyBytesPerRow * inBuffer->height;
	
	// allocate memory for, and create a vImage buffer struct for the dest buffer
	void *chunkyBuf = valloc(chunkyBufSize);
	
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
	
	DDCAssert(error == kvImageNoError, @"Error converting 3xPlanarF -> RGBX: %li", error);
	
	// return the buffer
	return (TSInterleavedBufferRGBX) {
		.data = chunkyBuf,
		
		.bytes_per_line = chunkyBytesPerRow,
		.width = inBuffer->width,
		.height = inBuffer->height
	};
}