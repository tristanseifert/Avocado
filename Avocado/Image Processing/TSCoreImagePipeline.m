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
			kCIContextUseSoftwareRenderer: @YES,
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
	NSBitmapImageRep *bm;
	
	// prepare job (connects the filters)
	[job prepareForRendering];
	
	// use generic colour space if not specified
	if(colourSpace == nil) {
		colourSpace = [NSColorSpace sRGBColorSpace];
	}
	
	// determine bits/pixel and pixel format
	CIFormat fmt;
	NSUInteger bytesPerPixel, bitsPerSample, bitsPerPixel;
	
	switch(format) {
		case TSCIPixelFormatRGBA8:
			fmt = kCIFormatRGBA8;
			bitsPerSample = 8;
			break;
			
		case TSCIPixelFormatRGBA16:
			fmt = kCIFormatRGBA16;
			bitsPerSample = 16;
			break;
			
		case TSCIPixelFormatRGBAf:
			fmt = kCIFormatRGBAf;
			bitsPerSample = 32;
			break;
	}
	
	bitsPerPixel = (bitsPerSample * 4);
	bytesPerPixel = (bitsPerPixel / 8);
	
	// set up a bitmap buffer
	NSUInteger bytesPerRow = job.result.extent.size.width * bytesPerPixel;
	NSUInteger bufSz = bytesPerRow * job.result.extent.size.height;
	
	NSUInteger width = job.result.extent.size.width;
	NSUInteger height = job.result.extent.size.height;
	
	// render into it
	void *buf = valloc(bufSz);
	[self.context render:job.result toBitmap:buf rowBytes:bytesPerRow
				  bounds:job.result.extent format:fmt
			  colorSpace:colourSpace.CGColorSpace];
	
	DDLogDebug(@"Allocating %li bytes for image size %@ (bpp = %li, bytes/row = %li)", bufSz, NSStringFromSize(job.result.extent.size), bitsPerPixel, bytesPerRow);
	DDLogDebug(@"Buffer = %p", buf);
	
	// create bitmap rep from it
	unsigned char *planes = { NULL };
	
	bm = [[TSBufferOwningBitmapRep alloc] initWithBitmapDataPlanes:&planes
														pixelsWide:width
														pixelsHigh:height
													 bitsPerSample:bitsPerSample
												   samplesPerPixel:4
														  hasAlpha:YES
														  isPlanar:NO
													colorSpaceName:NSCalibratedRGBColorSpace
													  bitmapFormat:0
													   bytesPerRow:bytesPerRow
													  bitsPerPixel:bitsPerPixel];
	
	memcpy(bm.bitmapData, buf, bufSz);
	free(buf);
	
	// create image
	NSImage *im = [[NSImage alloc] initWithSize:job.result.extent.size];
	[im addRepresentation:bm];
	
	return im;
	
	// convert to CIImage (this causes rendering)
//	CGImageRef im = [self.context createCGImage:job.result fromRect:job.result.extent];
//	return [[NSImage alloc] initWithCGImage:im size:NSZeroSize];

//	NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:job.result];
//	NSImage *nsImage = [[NSImage alloc] initWithSize:rep.size];
//	[nsImage addRepresentation:rep];
//	
//	return nsImage;
}

@end
