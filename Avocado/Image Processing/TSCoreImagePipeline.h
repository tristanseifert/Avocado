//
//  TSCoreImagePipeline.h
//  Avocado
//
//	Applies the specified image transformations to the image, utilizing
//	a GPU-bound CoreImage context;
//
//  Created by Tristan Seifert on 20160508.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#include "TSCoreImagePipelineJob.h"

#import <Foundation/Foundation.h>

/**
 * Output pixel formats
 */
typedef NS_ENUM(NSUInteger, TSCoreImagePixelFormat) {
	TSCIPixelFormatRGBA8, // 32bpp RGBA, int
	TSCIPixelFormatRGBA16, // 64bpp RGBA, int
	TSCIPixelFormatRGBAf, // 128bpp RGBA, float
};

@interface TSCoreImagePipeline : NSObject

/**
 * Produces an image from the specified pipeline job. If the object has
 * not yet had its filters connected to one another, this will be done
 * as well.
 *
 * @param job A pipeline rendering job object.
 * @param format Pixel format for the output image.
 * @param colourSpace Output colour space, or nil to use a generic RGB
 * space.
 * 
 * @return The output image of the pipeline.
 */
- (NSImage *) produceImageFromJob:(TSCoreImagePipelineJob *) job inPixelFormat:(TSCoreImagePixelFormat) format andColourSpace:(NSColorSpace *) colourSpace;


@end
