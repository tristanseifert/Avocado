//
//  TSPixelFormatConverter.m
//  Avocado
//
//  Created by Tristan Seifert on 20160503.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <memory.h>

#import <Accelerate/Accelerate.h>

#import "TSPixelFormatConverter.h"

static void TSAllocateBuffers(TSPixelConverterRef info);
static void TSFreeBuffers(TSPixelConverterRef converter);

static inline vImage_Buffer TSRawPipelinevImageBufferForPlane(TSPixelConverterRef converter, NSUInteger plane);

#pragma mark Types
/**
 * Pipeline pixel convertion state structure. This contains pointers to the
 * various buffers used, as well as some information about the source image and
 * its data.
 */
struct TSPixelConverter {
	/// Input data, 48bpp unsigned int RGB
	uint16_t *inData;
	
	/// Buffer for final output (interleaved floating point RGBA, 128bpp)
	Pixel_FFFF *outData;
	/// Size of the outData buffer
	size_t outDataSize;
	/// Number of bytes per line in the output data
	size_t outDataBytesPerLine;
	
	/// Buffer for interleaved three component floating point RGB
	Pixel_F *interleavedFloatData;
	/// Number of bytes per line in the interleaved float data
	size_t interleavedFloatDataBytesPerLine;
	
	/// Buffers for each of the R, G and B planes
	Pixel_F *plane[3];
	/// Size of each of the planes
	size_t planeSize;
	/// Number of bytes per line in each of the planes
	size_t planeBytesPerLine;
	
	/// width of the source image
	NSUInteger inWidth;
	/// height of the source image
	NSUInteger inHeight;
};

#pragma mark Initializers
/**
 * Sets up an instance of the conversion pipeline, with the given input data
 * and size.
 */
TSPixelConverterRef TSPixelConverterCreate(void *inData, NSUInteger inWidth, NSUInteger inHeight) {
	// validate parameters
	DDCAssert(inWidth > 0, @"width may not be 0");
	DDCAssert(inHeight > 0, @"height may not be 0");
	
	// allocate memory for an info struct
	TSPixelConverterRef info = calloc(1, sizeof(struct TSPixelConverter));
	
	// copy size
	info->inWidth = inWidth;
	info->inHeight = inHeight;
	
	// copy pointer
	info->inData = inData;
	
	// allocate the buffers
	TSAllocateBuffers(info);
	
	return info;
}

/**
 * Allocates internal buffers.
 */
static void TSAllocateBuffers(TSPixelConverterRef info) {
	// assume no additional packing in bytes/line for interleaved float data
	info->interleavedFloatDataBytesPerLine = (info->inWidth * 3 * sizeof(Pixel_F));
	
	// calculate bytes/line and buffer size for output
	info->outDataBytesPerLine = info->inWidth * sizeof(Pixel_FFFF);
	
	if(info->outDataBytesPerLine & 0x1F) {
		// align to a 32 byte boundary
		info->outDataBytesPerLine += (0x20 - (info->outDataBytesPerLine & 0x1F));
	}
	
	info->outDataSize = info->outDataBytesPerLine * info->inHeight;
	
	// calculate bytes/line and buffer size for each of the planes
	info->planeBytesPerLine = info->inWidth * sizeof(Pixel_F);
	
	if(info->planeBytesPerLine & 0x1F) {
		// align to a 32 byte boundary
		info->planeBytesPerLine += (0x20 - (info->planeBytesPerLine & 0x1F));
	}
	
	info->planeSize = info->planeBytesPerLine * info->inHeight;
	
	
	// allocate buffers
	info->outData = (Pixel_FFFF *) valloc(info->outDataSize);
	
	for(NSUInteger i = 0; i < 3; i++) {
		info->plane[i] = (Pixel_F *) valloc(info->planeSize);
	}
	
	/*
	 * To save on memory, use the 4 component buffer for the 3 component
	 * interleaved data, since that is only needed temporarily while the data
	 * is converted to planar format.
	 */
	info->interleavedFloatData = (Pixel_F *) info->outData;
}

/**
 * Destroys the given pixel conveter, deallocating any memory that was allocated
 * previously.
 */
void TSPixelConverterFree(TSPixelConverterRef converter) {
	// free buffers
	TSFreeBuffers(converter);
	
	// free the structure itself
	free(converter);
}

/**
 * Frees the internal buffers.
 */
static void TSFreeBuffers(TSPixelConverterRef converter) {
	// free the buffers
	for(NSUInteger i = 0; i < 3; i++) {
		free(converter->plane[i]);
	}
	
	// free the interleaved float and output data pointers
	free(converter->interleavedFloatData);
	
	if(((intptr_t) converter->interleavedFloatData) != ((intptr_t) converter->outData))
		free(converter->outData);
}

/**
 * Resizes the pixel converter to the given size. The old memory will be de-
 * allocated, and new buffers are allocated. No data is copied.
 */
void TSPixelConverterResize(TSPixelConverterRef converter, NSUInteger newWidth, NSUInteger newHeight) {
	// free old buffers
	
	// set new height
	converter->inWidth = newWidth;
	converter->inHeight = newHeight;
	
	// allocate new buffers
	TSAllocateBuffers(converter);
}

#pragma mark Helpers
/**
 * Returns a prepopulated vImage struct for one of the three planes of a given
 * converter.
 */
static inline vImage_Buffer TSRawPipelinevImageBufferForPlane(TSPixelConverterRef converter, NSUInteger plane) {
	return (vImage_Buffer) {
		.data = converter->plane[plane],
		.rowBytes = converter->planeBytesPerLine,
		.width = converter->inWidth,
		.height = converter->inHeight
	};
}

#pragma mark Getters
/**
 * Returns a pointer to the original input data.
 *
 * @param converter Converter whose info to return.
 */
void *TSPixelConverterGetOriginalData(TSPixelConverterRef converter) {
	return converter->inData;
}

/**
 * Returns a pointer to the final RGBX data.
 *
 * @param converter Converter whose info to return.
 */
Pixel_FFFF *TSPixelConverterGetRGBXPointer(TSPixelConverterRef converter) {
	return converter->outData;
}

/**
 * Places the width and height in the given pointer variables.
 *
 * @param converter Converter from which to get the information.
 * @param outWidth Pointer to a variable to hold width, or NULL.
 * @param outHeight Pointer to a variable to hold height, or NULL.
 */
void TSPixelConverterGetSize(TSPixelConverterRef converter, NSUInteger *outWidth, NSUInteger *outHeight) {
	// width
	if(outWidth != NULL)
		*outWidth = converter->inWidth;
	
	// height
	if(outHeight != NULL)
		*outHeight = converter->inHeight;
}

/**
 * Returns the vImage buffer for a given plane.
 *
 * @param converter Converter from which to get the information.
 * @param plane The numbered plane for which to get data, in the range [0..2].
 */
vImage_Buffer TSPixelConverterGetPlanevImageBufferBuffer(TSPixelConverterRef converter, NSUInteger plane) {
	// just use the internal function for now
	return TSRawPipelinevImageBufferForPlane(converter, plane);
}

#pragma mark Setters
/**
 * Sets the RGB data input buffer.
 *
 * @param converter Converter whose input buffer to set.
 * @param inData Input data buffer.
 */
void TSPixelConverterSetInData(TSPixelConverterRef converter, void *inData) {
	converter->inData = inData;
}

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
BOOL TSPixelConverterRGB16UToFloat(TSPixelConverterRef converter, uint16_t maxValue) {
	vImage_Error error = kvImageNoError;
	vImage_Buffer vImageBufIn, vImageBufOut;
	
	// validate parameters
	DDCAssert(converter != NULL, @"converter may not be NULL");
	DDCAssert(maxValue > 0, @"maximum value may not be 0");
	
	// calculate the scale of input values
	float scale = 1 / ((float) maxValue);
	
	// create a vImage buffer for the input and output
	vImageBufIn = (vImage_Buffer) {
		.data = converter->inData,
		.width = (converter->inWidth * 3), // trick to convert each component
		.height = converter->inHeight,
		.rowBytes = (converter->inWidth * 3 * sizeof(uint16_t))
	};
	
	vImageBufOut = (vImage_Buffer) {
		.data = converter->interleavedFloatData,
		.width = (converter->inWidth * 3),
		.height = converter->inHeight,
		.rowBytes = converter->interleavedFloatDataBytesPerLine
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
BOOL TSPixelConverterRGBFFFToPlanarF(TSPixelConverterRef converter) {
	vImage_Error error = kvImageNoError;
	
	// validate parameters
	DDCAssert(converter != NULL, @"converter may not be NULL");
	
	// create vImage descriptors for all three planes
	vImage_Buffer vImageBufR = TSRawPipelinevImageBufferForPlane(converter, 0);
	vImage_Buffer vImageBufG = TSRawPipelinevImageBufferForPlane(converter, 1);
	vImage_Buffer vImageBufB = TSRawPipelinevImageBufferForPlane(converter, 2);
	
	// set up struct for input buffer
	vImage_Buffer vImageBufIn = {
		.data = converter->interleavedFloatData,
		.width = converter->inWidth,
		.height = converter->inHeight,
		.rowBytes = converter->interleavedFloatDataBytesPerLine
	};
	
	// perform the conversion and check for errors
	error = vImageConvert_RGBFFFtoPlanarF(&vImageBufIn, &vImageBufR, &vImageBufG, &vImageBufB, kvImageNoFlags);
	
	if(error != kvImageNoError) {
		DDLogError(@"Error converting RGBFFF -> PlanarF: %li", error);
		return NO;
	}
	
	// we're done
	return YES;
}

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
BOOL TSPixelConverterPlanarFToRGBXFFFF(TSPixelConverterRef converter) {
	vImage_Error error = kvImageNoError;
	
	// validate parameters
	DDCAssert(converter != NULL, @"converter may not be NULL");
	
	// create vImage buffer struct for output buffer
	vImage_Buffer vImageBufDest = {
		.data = converter->outData,
		.rowBytes = converter->outDataBytesPerLine,
		.width = converter->inWidth,
		.height = converter->inHeight
	};
	
	// create vImage descriptors for all three planes
	vImage_Buffer vImageBufR = TSRawPipelinevImageBufferForPlane(converter, 0);
	vImage_Buffer vImageBufG = TSRawPipelinevImageBufferForPlane(converter, 1);
	vImage_Buffer vImageBufB = TSRawPipelinevImageBufferForPlane(converter, 2);
	
	// perform the conversion and check for errors
	error = vImageConvert_PlanarFToRGBXFFFF(&vImageBufR, &vImageBufG, &vImageBufB, 1.f, &vImageBufDest, kvImageNoFlags);
	
	if(error != kvImageNoError) {
		DDLogError(@"Error converting 3xPlanarF -> RGBX: %li", error);
		return NO;
	}
	
	// we're done
	return YES;
}