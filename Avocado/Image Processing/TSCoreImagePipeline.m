//
//  TSCoreImagePipeline.m
//  Avocado
//
//  Created by Tristan Seifert on 20160508.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreImagePipeline.h"
#import "TSCoreImagePipelineJob.h"

#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#import <AppKit/AppKit.h>

@interface TSCoreImagePipeline ()

/// CoreImage context; hardware-accelerated processing for filters
@property (nonatomic) CIContext *context;

@end

@implementation TSCoreImagePipeline

/**
 * Initializes the CoreImage pipeline.
 */
- (instancetype) init {
	if(self = [super init]) {
		
		// set up CoreImage context
		NSDictionary *ciOptions = @{
			// request GPU rendering if possible
			kCIContextUseSoftwareRenderer: @NO,
			// use 128bpp floating point RGBA format
			kCIContextWorkingFormat: @(kCIFormatRGBAf),
		};
		
		self.context = [CIContext contextWithOptions:ciOptions];
		DDAssert(self.context != nil, @"Could not allocate CIContext");
	}
	
	return self;
}

#pragma mark Image Secretion
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
- (NSImage *) produceImageFromJob:(TSCoreImagePipelineJob *) job
					inPixelFormat:(TSCoreImagePixelFormat) format
				   andColourSpace:(NSColorSpace *) colourSpace {
	CGImageRef image;
	
	// prepare job
	[job prepareForRendering];
	
	// determine the colour space to use
	CGColorSpaceRef cs;
	
	if(colourSpace) {
		cs = colourSpace.CGColorSpace;
	} else {
		// TODO: figure out a better alternative
		cs = [NSColorSpace sRGBColorSpace].CGColorSpace;
	}
	
	// determine pixel format
	CIFormat pixFmt;
	
	switch(format) {
		case TSCIPixelFormatRGBA8:
			pixFmt = kCIFormatRGBA8;
			break;
			
		case TSCIPixelFormatRGBA16:
			pixFmt = kCIFormatRGBA16;
			break;
			
		case TSCIPixelFormatRGBAf:
			pixFmt = kCIFormatRGBAf;
			break;
	}
	
	// render in context
	image = [self.context createCGImage:job.result
							   fromRect:job.result.extent
								 format:pixFmt
							 colorSpace:cs];
	
	// convert to NSImage and return
	return [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
}

@end
