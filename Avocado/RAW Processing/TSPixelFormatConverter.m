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

#define LogMemAlloc	1

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
	
	/// When set, the buffers are treated as rotated, i.e. width/height are swapped.
	BOOL planesAreRotated;
	
	/// Buffer for final output (interleaved floating point RGBA, 128bpp)
	Pixel_FFFF *outData;
	/// Size of the outData buffer
	size_t outDataSize;
	/// Number of bytes per line in the output data
	size_t outDataBytesPerLine;
	/// Number of bytes per line in the output data, if rotated
	size_t outDataBytesPerLineRotated;
	
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
	/// Number of bytes per line in each of the planes, if width/height are swapped
	size_t planeBytesPerLineRotated;
	
	/// Temporary buffer, the size of a plane, to use for geometric operations.
	Pixel_F *planeTempBuffer;
	
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
	size_t rotatedSize;
	
	// assume no additional packing in bytes/line for interleaved float data
	info->interleavedFloatDataBytesPerLine = (info->inWidth * 3 * sizeof(Pixel_F));
	
	// calculate bytes/line and buffer size for output
	info->outDataBytesPerLine = info->inWidth * sizeof(Pixel_FFFF);
	
	if(info->outDataBytesPerLine & 0x1F) {
		// align to a 32 byte boundary
		info->outDataBytesPerLine += (0x20 - (info->outDataBytesPerLine & 0x1F));
	}
	
	info->outDataSize = info->outDataBytesPerLine * info->inHeight;
	
	// calculate bytes/line for output, if rotated
	info->outDataBytesPerLineRotated = info->inHeight * sizeof(Pixel_FFFF);
	
	if(info->outDataBytesPerLineRotated & 0x1F) {
		// align to a 32 byte boundary
		info->outDataBytesPerLineRotated += (0x20 - (info->outDataBytesPerLineRotated & 0x1F));
	}
	
	// check if the rotated size is larger than the regular size
	rotatedSize = info->outDataBytesPerLineRotated * info->inWidth;
	
	if(info->planeSize < rotatedSize) {
		printf("TSPixelConverter: OutBuf rotated size (%lu) is larger than regular size (%li)\n", rotatedSize, info->outDataSize);
		
		info->outDataSize = rotatedSize;
	}
	
	
	// calculate bytes/line and buffer size for each of the planes
	info->planeBytesPerLine = info->inWidth * sizeof(Pixel_F);
	
	if(info->planeBytesPerLine & 0x1F) {
		// align to a 32 byte boundary
		info->planeBytesPerLine += (0x20 - (info->planeBytesPerLine & 0x1F));
	}
	
	info->planeSize = info->planeBytesPerLine * info->inHeight;
	
	// calculate swapped bytes/line of the plane
	info->planeBytesPerLineRotated = info->inHeight * sizeof(Pixel_F);
	
	if(info->planeBytesPerLineRotated & 0x1F) {
		// align to a 32 byte boundary
		info->planeBytesPerLineRotated += (0x20 - (info->planeBytesPerLineRotated & 0x1F));
	}
	
	// check if the swapped size is larger than the regular size
	rotatedSize = info->planeBytesPerLineRotated * info->inWidth;
	
	if(info->planeSize < rotatedSize) {
		printf("TSPixelConverter: Plane's rotated size (%lu) is larger than regular size (%li)\n", rotatedSize, info->planeSize);
		
		info->planeSize = rotatedSize;
	}
	
	
	// allocate buffers
	info->outData = (Pixel_FFFF *) valloc(info->outDataSize);
	
#if LogMemAlloc
	printf("TSPixelConverter: Allocated %lu bytes for outData\n", info->outDataSize);
#endif
	
	for(NSUInteger i = 0; i < 3; i++) {
		info->plane[i] = (Pixel_F *) valloc(info->planeSize);
		
#if LogMemAlloc
		printf("TSPixelConverter: Allocated %lu bytes for plane %i\n", info->planeSize, (int) i);
#endif
	}
	
	info->planeTempBuffer = (Pixel_F *) valloc(info->planeSize);
	
#if LogMemAlloc
	printf("TSPixelConverter: Allocated %lu bytes for plane temp buffer\n", info->planeSize);
#endif
	
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
	
	free(converter->planeTempBuffer);
	
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
	if(converter->planesAreRotated == NO) {
		// regular, non-rotated plane
		return (vImage_Buffer) {
			.data = converter->plane[plane],
			.rowBytes = converter->planeBytesPerLine,
			.width = converter->inWidth,
			.height = converter->inHeight
		};
	} else {
		// rotated plane
		return (vImage_Buffer) {
			.data = converter->plane[plane],
			.rowBytes = converter->planeBytesPerLineRotated,
			.width = converter->inHeight,
			.height = converter->inWidth
		};
	}
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
 * Returns the stride (bytes / row) of the output buffer.
 *
 * @param Converter whose info to return.
 */
size_t TSPixelConverterGetRGBXStride(TSPixelConverterRef converter) {
	// planes are rotated
	if(converter->planesAreRotated) {
		return converter->outDataBytesPerLineRotated;
	}
	// regular, un-rotated output
	else {
		return converter->outDataBytesPerLine;
	}
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
	
	// handle rotation for the output buffer
	if(converter->planesAreRotated) {
		vImageBufDest.rowBytes = converter->outDataBytesPerLineRotated;
		
		// flip the width/heights
		NSUInteger width = vImageBufDest.width, height = vImageBufDest.height;
		
		vImageBufDest.height = width;
		vImageBufDest.width = height;
	}
	
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

#pragma mark Geometric Operations
/**
 * Rotates the image by the given multiple of 90 degrees. 0 is no rotation, 1 is
 * 90° counter-clockwise, and so forth.
 *
 * @param converter Converter object whose planes should be converted.
 * @param rotation Rotation, multiple of 90°.
 *
 * @return YES if successful, NO otherwise.
 */
BOOL TSPixelConverterRotate90(TSPixelConverterRef converter, ssize_t rotation) {
	vImage_Error error;
	vImage_Buffer inBuf, outBuf;
	
	// we need to rotate each plane separately
	for(int c = 0; c < 3; c++) {
		inBuf = TSRawPipelinevImageBufferForPlane(converter, c);
		
		// use the same specifications as the input buffer, but write to temp buffer
		outBuf = inBuf;
		outBuf.data = converter->planeTempBuffer;
		
		// see if the out buffer needs changes to its stride/
		if(rotation != kRotate0DegreesClockwise && rotation != kRotate180DegreesClockwise) {
			outBuf.rowBytes = converter->planeBytesPerLineRotated;
			
			// flip the width/heights
			NSUInteger width = outBuf.width, height = outBuf.height;
			
			outBuf.height = width;
			outBuf.width = height;
		}
		
		// do the rotation
		error = vImageRotate90_PlanarF(&inBuf, &outBuf, (uint8_t) rotation, 1.f, kvImageNoFlags);
		
		if(error != kvImageNoError) {
			DDLogError(@"Error rotating PlanarF (%li): %li", rotation, error);
			return NO;
		}
		
		// copy the data from the temp buffer to the actual buffer
		memcpy(inBuf.data, outBuf.data, converter->planeSize);
	}
	
	// set the rotated flag, if rotation changed the image dimensions
	if(rotation != kRotate0DegreesClockwise && rotation != kRotate180DegreesClockwise) {
		converter->planesAreRotated = YES;
	} else {
		converter->planesAreRotated = NO;
	}
	
	// successed
	return YES;
}