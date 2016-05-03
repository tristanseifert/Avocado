//
//  TSRawPipeline_types.h
//  Avocado
//
//	Various types used by the RAW processing pipeline.
//
//  Created by Tristan Seifert on 20160503.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#ifndef TSRawPipeline_types_h
#define TSRawPipeline_types_h

#pragma mark Types
/**
 * Struct that encompasses a planar RGB vImage buffer.
 */
typedef struct _TSPlanarBufferRGB {
	/// planar buffer for the red, green and blue (in that order) components
	void *components[3];
	
	/// how many bytes are in each line; this is the same for each plane.
	size_t bytes_per_line;
	/// width and height of the image; this is the same for each plane.
	size_t width, height;
} TSPlanarBufferRGB;

/**
 * Struct that encompasses an interleaved RGBX image buffer.
 */
typedef struct _TSInterleavedBufferRGBX {
	/// pointer to the actual buffer data
	void *data;
	
	/// how many bytes are in each line
	size_t bytes_per_line;
	/// width and height of the image
	size_t width, height;
} TSInterleavedBufferRGBX;

#pragma mark Helper Functions
/**
 * Disposes of a planar buffer. This has the effect of deallocating all
 * of the planes' memory.
 */
static inline void TSFreePlanarBufferRGB(TSPlanarBufferRGB *buffer) {
	// free red component
	if(buffer->components[0] != NULL)
		free(buffer->components[0]);
	
	// free green component
	if(buffer->components[1] != NULL)
		free(buffer->components[1]);
	
	// free blue component
	if(buffer->components[2] != NULL)
		free(buffer->components[2]);
}

/**
 * Disposes of an interleaved buffer. This has the effect of deallocating all of
 * the buffer's memory.
 */
static inline void TSFreeInterleavedBufferRGBX(TSInterleavedBufferRGBX *buffer) {
	// free buffer
	if(buffer->data != NULL)
		free(buffer->data);
}

#endif /* TSRawPipeline_types_h */
