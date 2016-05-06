//
//  TSRawPipelineState.h
//  Avocado
//
//  Created by Tristan Seifert on 20160504.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSRawPipeline.h"
#import "TSPixelFormatConverter.h"
#import "TSRawPipeline.h"

@class TSLibraryImage;
@class TSRawImage;
@interface TSRawPipelineState : NSObject

/// the current processing step
@property (nonatomic) TSRawPipelineStage stage;
/// a progress object with which to track progress
@property (nonatomic) NSProgress *progress;

/// library image that is being processed
@property (nonatomic, strong) TSLibraryImage *image;
/// raw image to be used
@property (nonatomic) TSRawImage *rawImage;
/// whether results of this processing step should be cached or naw
@property (nonatomic) BOOL shouldCache;

/// pixel format converter (may be shared/re-used)
@property (nonatomic) TSPixelConverterRef converter;

/// completion callback
@property (nonatomic) TSRawPipelineCompletionCallback completionCallback;
/// progress callback
@property (nonatomic) TSRawPipelineProgressCallback progressCallback;

/**
 * Adds an operation to the list of operations associated with the op.
 */
-(void) addOperation:(NSOperation *) op;

/**
 * Terminates the RAW pipeline with an error message.
 */
- (void) terminateWithError:(NSError *) err;

@end
