//
//  TSRawPipelineTest.m
//  Avocado
//
//  Created by Tristan Seifert on 20160506.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MagicalRecord/MagicalRecord.h>

#import "TSHumanModels.h"
#import "TSRawPipeline.h"

@interface TSRawPipelineTest : XCTestCase

/// the first RAW file we can find
@property (nonatomic) TSLibraryImage *image;
/// raw pipeline
@property (nonatomic) TSRawPipeline *pipeline;

@end

@implementation TSRawPipelineTest

- (void) setUp {
    [super setUp];
	
	// set up a raw pipeline
	self.pipeline = [TSRawPipeline new];
	
	// find the image
	NSArray<TSLibraryImage *> *images = [TSLibraryImage MR_findAll];
	
	[images enumerateObjectsUsingBlock:^(TSLibraryImage *image, NSUInteger idx, BOOL *stop) {
		// check filetype
		if(image.fileTypeValue == TSLibraryImageRaw) {
			// is it a CR2 file?
			if([image.fileUrl.lastPathComponent containsString:@".CR2"]) {
				self.image = image;
				
				*stop = YES;
			}
		}
	}];
}

- (void) tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark Tests
/**
 * Performs a conversion of the first RAW file that can be found.
 */
- (void) testRawConversion {
	XCTAssertNotNil(self.image, @"Couldn't find a RAW image");
	DDLogVerbose(@"Using image: %@", self.image.fileUrl);
	
	// set up expectation for the RAW conversion
	XCTestExpectation *expectation = [self expectationWithDescription:@"RAW Conversion"];
	
	// queue RAW thing
	NSProgress *progress = nil;
	
	[self.pipeline queueRawFile:self.image shouldCache:NO
			 completionCallback:^(NSImage *img, NSError *err) {
				 if(err) {
					 DDLogError(@"Error processing RAW file: %@", err);
				 } else {
					 DDLogDebug(@"Processed image file: %@", img);
					 
					 // write image out to disk
					 NSFileManager *fm = [NSFileManager defaultManager];
					 NSURL *appSupportURL = [[fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
					 appSupportURL = [appSupportURL URLByAppendingPathComponent:@"me.tseifert.Avocado"];
					 
					 NSData *tiff = [img TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:1];
					 
					 [tiff writeToURL:[appSupportURL URLByAppendingPathComponent:@"testRawConversion_result.tiff"] atomically:YES];
				 }
				 
				 // fulfill expectation
				 [expectation fulfill];
			 }
			   progressCallback:^(TSRawPipelineStage stage) {
				   DDLogDebug(@"At RAW Processing Stage: %lu", stage);
			   }
			 conversionProgress:&progress];
	
	// wait
	[self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
		if(error) {
			DDLogError(@"Error meeting RAW conversion expectation: %@", error);
		} else {
			DDLogDebug(@"RAW conversion expectation met");
		}
	}];
}

/**
 * Performs a conversion of the first RAW file that can be found, ten times
 * over to acquire some performance metrics.
 */
- (void) testRawConversionSpeed {
	XCTAssertNotNil(self.image, @"Couldn't find a RAW image");
	DDLogVerbose(@"Using image: %@", self.image.fileUrl);
	
	// do conversion
	[self measureBlock:^{
		// set up expectation for the RAW conversion
		XCTestExpectation *expectation = [self expectationWithDescription:@"RAW Conversion"];
		
		// queue RAW thing
		NSProgress *progress = nil;
		
		[self.pipeline queueRawFile:self.image shouldCache:NO
				 completionCallback:^(NSImage *img, NSError *err) {
					 if(err) {
						 DDLogError(@"Error processing RAW file: %@", err);
						 
						 [expectation fulfill];
					 } else {
						 [expectation fulfill];
					 }
				 }
				   progressCallback:^(TSRawPipelineStage stage) {
					   DDLogDebug(@"At RAW Processing Stage: %lu", stage);
				   }
				 conversionProgress:&progress];
		
		// wait
		[self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
			if(error) {
				DDLogError(@"Error meeting RAW conversion expectation: %@", error);
			} else {
				DDLogDebug(@"RAW conversion expectation met");
			}
		}];
	}];
}


@end
