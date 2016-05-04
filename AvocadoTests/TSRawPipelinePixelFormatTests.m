//
//  TSRawPipelinePixelFormatTests.m
//  AvocadoTests
//
//  Created by Tristan Seifert on 20160503.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TSRawPipeline_PixelFormat.h"

/// sets the size of the test
static NSUInteger imgWidth = 1024;
static NSUInteger imgHeight = 768;

@interface TSRawPipelinePixelFormatTests : XCTestCase

@property (nonatomic) uint16_t *imageBuffer;

// re-useable helpers
- (void *) produceFloatBufferInterleaved;
- (TSPlanarBufferRGB *) producePlanarFromInterleaved:(void *) inBuf;
- (TSInterleavedBufferRGBX *) produceInterleavedFromPlanar:(TSPlanarBufferRGB *) inBuf;

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
}

- (void) tearDown {
	// free the buffer
	free(self.imageBuffer);
	
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
		Pixel_F *floatData = [self produceFloatBufferInterleaved];
		
		// ensure it isn't nil
		XCTAssert(floatData != NULL, @"Error during short -> float conversion");
		
		// ensure that there are certain test values
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
		// first, convert to float
		Pixel_F *floatData = [self produceFloatBufferInterleaved];
		XCTAssert(floatData != NULL, @"Error during short -> float conversion");
		
		// convert pls
		TSPlanarBufferRGB *buf = [self producePlanarFromInterleaved:floatData];
		
		// ensure it isn't nil
		XCTAssert(buf != NULL, @"Error during float interleaved -> planar");
		
		// ensure that there are certain test values
		XCTAssertEqual(buf->components[0][0], 0.25f, @"plane[0][0] (R) != 0.25");
		XCTAssertEqual(buf->components[1][0], 0.5f, @"plane[1][0] (G) != 0.5");
		XCTAssertEqual(buf->components[2][0], 1.f, @"plane[2][0] (B) != 1.0");
		
		// clean up
//		free(floatData);
//		TSFreePlanarBufferRGB(buf);
	}];
}

/**
 * Tests the conversion of the planar floating point data to an
 * interlaced 128bpp RGBX format.
 */
- (void) testPlanarFToRGBXFFFF {
	// time conversion to planar
	[self measureBlock:^{
		// first, convert to float
		Pixel_F *floatData = [self produceFloatBufferInterleaved];
		XCTAssert(floatData != NULL, @"Error during short -> float conversion");
		
		// convert to planar
		TSPlanarBufferRGB *buf = [self producePlanarFromInterleaved:floatData];
		
		// now, convert to RGBX (alpha should be fixed at 1.f)
		TSInterleavedBufferRGBX *bufInterleaved = [self produceInterleavedFromPlanar:buf];
		
		// ensure it isn't nil
		XCTAssert(bufInterleaved != NULL, @"Error during float planar -> interleaved");
		
		// ensure that there are certain test values
		XCTAssertEqual(bufInterleaved->data[0], 0.25f, @"data[0] (R) != 0.25");
		XCTAssertEqual(bufInterleaved->data[1], 0.5f, @"data[1] (G) != 0.5");
		XCTAssertEqual(bufInterleaved->data[2], 1.f, @"data[2] (B) != 1.0");
		
		XCTAssertEqual(bufInterleaved->data[3], 1.f, @"data[3] (alpha) != 1.0");
	}];
}

#pragma mark Helpers (re-useable components)
/**
 * Converts the uint16_t input RGB array to floating point.
 */
- (void *) produceFloatBufferInterleaved {
	BOOL success;
	
	// allocate a buffer into which the floating data goes, and convert
	Pixel_F *floatData = valloc(imgWidth * imgHeight * 3 * sizeof(Pixel_F));
	success = TSRawPipelineConvertRGB16UToFloat(self.imageBuffer, imgWidth, imgHeight, 0x4000, floatData);
	
	// ensure it isn't nil
	XCTAssert(success == YES, @"Error during conversion from short to float");
	
	return floatData;
}

/**
 * Converts the given interleaved buffer to planar.
 */
- (TSPlanarBufferRGB *) producePlanarFromInterleaved:(void *) inBuf {
	TSPlanarBufferRGB *buf = TSRawPipelineConvertRGBFFFToPlanarF(inBuf, imgWidth, imgHeight);
	
	// ensure it isn't nil
	XCTAssert(buf != NULL, @"Error during chunky -> planar conversion");
	return buf;
}

/**
 * Converts the given planar buffer to an RGBX interleaved buffer.
 */
- (TSInterleavedBufferRGBX *) produceInterleavedFromPlanar:(TSPlanarBufferRGB *) inBuf {
	TSInterleavedBufferRGBX *buf = TSRawPipelineConvertPlanarFToRGBXFFFF(inBuf);
	
	// ensure it isn't nil
	XCTAssert(buf != NULL, @"Error during chunky -> planar conversion");
	return buf;
}

@end
