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
	self.image = [TSLibraryImage MR_findFirstByAttribute:@"fileType" withValue:@(TSLibraryImageRaw)];
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

	NSProgress *progress = nil;
	
	// set up expectation for the RAW conversion
	XCTestExpectation *expectation = [self expectationWithDescription:@"RAW Conversion"];
	
	// do conversion
	[self.pipeline queueRawFile:self.image shouldCache:NO
			 completionCallback:^(NSImage *img, NSError *err) {
				 if(err) {
					 DDLogError(@"Error processing RAW file: %@", err);
				 } else {
					 DDLogDebug(@"Processed RAW file: %@", img);
				 }
				 
				 // fulfill expectation
				 [expectation fulfill];
	}
			   progressCallback:^(TSRawPipelineStage stage) {
				   DDLogDebug(@"At RAW Processing Stage: %lu", stage);
			   }
			 conversionProgress:&progress];
	
	// wait
	[self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
		if(error) {
			DDLogError(@"Error meeting RAW conversion expectation: %@", error);
		} else {
			DDLogDebug(@"RAW conversion expectation met");
		}
	}];
}


@end
