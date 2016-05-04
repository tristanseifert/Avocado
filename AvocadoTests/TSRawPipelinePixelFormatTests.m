//
//  TSRawPipelinePixelFormatTests.m
//  AvocadoTests
//
//  Created by Tristan Seifert on 20160503.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TSRawPipeline_PixelFormat.h"

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

/// sets the size of the test
static NSUInteger imgWidth = 5760; // 1024;
static NSUInteger imgHeight = 3840; // 768;

@interface TSRawPipelinePixelFormatTests : XCTestCase

@property (nonatomic) uint16_t *imageBuffer;
@property (nonatomic) TSPixelConverterRef converter;

@end

@implementation TSRawPipelinePixelFormatTests

- (void) setUp {
    [super setUp];
	
	// allocates an image buffer. We pretend to have a 1024x768 image, 24bpp.
	self.imageBuffer = (uint16_t *) valloc(imgWidth * imgHeight * 3 * sizeof(uint16_t));
	
	// fill it with some test data, first the y
	for(NSUInteger y = 0; y < imgHeight; y++) {
		// calc pointer
		uint16_t *imagePtr = self.imageBuffer + (y * imgWidth);
		
		// then fill the X
		for(NSUInteger x = 0; x < imgWidth; x++) {
			*imagePtr++ = 0x1000; // R
			*imagePtr++ = 0x2000; // G
			*imagePtr++ = 0x4000; // B
		}
	}
	
	// set up the converterizor pls.
	self.converter = TSRawPipelineCreateConverter(self.imageBuffer, imgWidth, imgHeight);
}

- (void) tearDown {
	// free the buffer
	free(self.imageBuffer);
	TSRawPipelineFreeConverter(self.converter);
	
	// perform super behaviour
    [super tearDown];
}

/**
 * Tests conversion of an RGB 16 bit/component buffer to an interleaved
 * floating-point format.
 */
- (void) testInterleaved16UToInterleavedF {
	// time conversion to float data
	[self measureBlock:^{
		BOOL success = TSRawPipelineConvertRGB16UToFloat(self.converter, 0x4000);
		XCTAssertTrue(success, @"Error during short -> float conversion");
		
		// ensure that there are certain test values
		Pixel_F *floatData = self.converter->interleavedFloatData;
		
		XCTAssertEqual(floatData[0], 0.25f, @"imageData[0] (R) != 0.25");
		XCTAssertEqual(floatData[1], 0.5f, @"imageData[1] (G) != 0.5");
		XCTAssertEqual(floatData[2], 1.f, @"imageData[2] (B) != 1.0");
		
		// clean up
//		free(floatData);
	}];
}

/**
 * Tests conversion of an interleaved RGB buffer to a planar buffer.
 */
- (void) testInterleavedFToPlanarF {
	// time conversion to planar
	[self measureBlock:^{
		BOOL success;
		
		// first, convert to float
		success = TSRawPipelineConvertRGB16UToFloat(self.converter, 0x4000);
		XCTAssertTrue(success, @"Error during short -> float conversion");
		
		// convert to planar
		success = TSRawPipelineConvertRGBFFFToPlanarF(self.converter);
		XCTAssertTrue(success, @"Error during float interleaved -> planar");
		
		// ensure that there are certain test values
		XCTAssertEqual(self.converter->plane[0][0], 0.25f, @"plane[0][0] (R) != 0.25");
		XCTAssertEqual(self.converter->plane[1][0], 0.5f, @"plane[1][0] (G) != 0.5");
		XCTAssertEqual(self.converter->plane[2][0], 1.f, @"plane[2][0] (B) != 1.0");
	}];
}

/**
 * Tests the conversion of the planar floating point data to an
 * interlaced 128bpp RGBX format.
 */
- (void) testPlanarFToRGBXFFFF {
	// time conversion to planar
	[self measureBlock:^{
		BOOL success;
		
		// first, convert to float
		success = TSRawPipelineConvertRGB16UToFloat(self.converter, 0x4000);
		XCTAssertTrue(success, @"Error during short -> float conversion");
		
		// convert to planar
		success = TSRawPipelineConvertRGBFFFToPlanarF(self.converter);
		XCTAssertTrue(success, @"Error during float interleaved -> planar");
		
		// now, convert to RGBX (alpha should be fixed at 1.f)
		success = TSRawPipelineConvertPlanarFToRGBXFFFF(self.converter);
		XCTAssertTrue(success, @"Error during float planar -> interleaved");
		
		// ensure that there are certain test values
		Pixel_F *data = (Pixel_F *) TSRawPipelineGetRGBXPointer(self.converter);
		
		XCTAssertEqual(data[0], 0.25f, @"data[0] (R) != 0.25");
		XCTAssertEqual(data[1], 0.5f, @"data[1] (G) != 0.5");
		XCTAssertEqual(data[2], 1.f, @"data[2] (B) != 1.0");
		
		XCTAssertEqual(data[3], 1.f, @"data[3] (alpha) != 1.0");
	}];
}

@end
