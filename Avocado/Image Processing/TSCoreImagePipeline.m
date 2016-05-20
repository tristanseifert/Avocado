//
//  TSCoreImagePipeline.m
//  Avocado
//
//  Created by Tristan Seifert on 20160508.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreImagePipeline.h"
#import "TSCoreImagePipelineJob.h"

#import "TSBufferOwningBitmapRep.h"

#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#import <AppKit/AppKit.h>

/**
 * When set to a nonzero value, information about buffer allocation will
 * be logged.
 */
#define LogBufferAllocations	0

@interface TSCoreImagePipeline ()

/// CoreImage context; hardware-accelerated processing for filters
@property (nonatomic) CIContext *context;

static void TSCoreImagePipelineFreeBuffer(void *info, const void *data, size_t size);

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
	CGImageRef im;
	CGDataProviderRef provider;
	
	// prepare job (connects the filters)
	[job prepareForRendering];
	
	// use generic colour space if not specified
	if(colourSpace == nil) {
		colourSpace = [NSColorSpace sRGBColorSpace];
	}
	
	// determine bits/pixel and pixel format
	CIFormat fmt;
	NSUInteger bytesPerPixel, bitsPerSample, bitsPerPixel;
	
	CGBitmapInfo bitmapInfo = (CGBitmapInfo) kCGImageAlphaPremultipliedLast;
	
	switch(format) {
		case TSCIPixelFormatRGBA8:
			fmt = kCIFormatRGBA8;
			bitsPerSample = 8;
			break;
			
		case TSCIPixelFormatRGBA16:
			fmt = kCIFormatRGBA16;
			bitsPerSample = 16;
			
			bitmapInfo |= kCGBitmapByteOrder16Host;
			break;
			
		case TSCIPixelFormatRGBAf:
			fmt = kCIFormatRGBAf;
			bitsPerSample = 32;
			
			bitmapInfo |= kCGBitmapFloatComponents;
			break;
	}
	
	bitsPerPixel = (bitsPerSample * 4);
	bytesPerPixel = (bitsPerPixel / 8);
	
	// set up a buffer, into which CoreImage renders
	NSUInteger bytesPerRow = job.result.extent.size.width * bytesPerPixel;
	NSUInteger bufSz = bytesPerRow * job.result.extent.size.height;
	
	NSUInteger width = job.result.extent.size.width;
	NSUInteger height = job.result.extent.size.height;

	void *buf = valloc(bufSz);
	
	// render into it with the requested pixel format
	[self.context render:job.result toBitmap:buf rowBytes:bytesPerRow
				  bounds:job.result.extent format:fmt
			  colorSpace:colourSpace.CGColorSpace];
	
#if LogBufferAllocations
	DDLogDebug(@"Allocating %li bytes for image size %@ (bpp = %li, bytes/row = %li)", bufSz, NSStringFromSize(job.result.extent.size), bitsPerPixel, bytesPerRow);
	DDLogDebug(@"Buffer = %p", buf);
#endif
	
	
	// create a direct access provider (with the buffer) and a CGImage
	provider = CGDataProviderCreateWithData(nil, buf, bufSz, TSCoreImagePipelineFreeBuffer);
	
	im = CGImageCreate(width, height, bitsPerSample, bitsPerPixel,
					   bytesPerRow, colourSpace.CGColorSpace, bitmapInfo,
					   provider, nil, YES, kCGRenderingIntentPerceptual);
	
	CGDataProviderRelease(provider);
	
	// create an NSImage encapsulating the CGImage
	NSImage *result =  [[NSImage alloc] initWithCGImage:im size:NSZeroSize];
	
	// this is important to prevent a memory leak
	CGImageRelease(im);
	
	return result;
}

/**
 * Called by CoreImage when our data provider (passed to the CGImageCreate
 * function) is no longer needed, for example, when the CGImage has been
 * released.
 */
static void TSCoreImagePipelineFreeBuffer(void *info, const void *data, size_t size) {
	free((void *) data);
}

@end
