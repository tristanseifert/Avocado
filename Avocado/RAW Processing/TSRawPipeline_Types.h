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

/*
 * Define any required Accelerate.framework types. This way, we needn't import
 * the header and save a bit of effort, and the type sizes should not change
 * any time soon.
 */
#ifndef Pixel_F
	typedef float       Pixel_F;
#endif
#ifndef Pixel_FFFFF
	typedef float       Pixel_FFFF[4];
#endif

#pragma mark Types
/**
 * Opaque type defining all data that the pixel conversion routines need to
 * properly operate, including pointers to memory.
 */
typedef struct TSPixelConverter* TSPixelConverterRef;

#endif /* TSRawPipeline_types_h */
