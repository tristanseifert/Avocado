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

#import "lensfun.h"

@class CIImage;
@class TSLibraryImage;
@class TSRawImage;
@interface TSRawPipelineState : NSObject

/// the current processing step
@property (nonatomic) TSRawPipelineStage stage;
/// a progress object with which to track progress
@property (nonatomic) NSProgress *progress;

/// library image that is being processed
@property (nonatomic, strong) TSLibraryImage *image;
/// UUID of the image
@property (nonatomic, strong) NSString *imageUuid;

/// raw image to be used
@property (nonatomic) TSRawImage *rawImage;
/// whether results of this processing step should be cached or naw
@property (nonatomic) BOOL shouldCache;

/// 64bpp buffer for the interpolated RGBX data; used by converter.
@property (nonatomic) void *interpolatedColourBuf;
/// histogram buffer; 0x2000 bins for each of the four possible colours, 32-bit int value per
@property (nonatomic) int *histogramBuf;
/// gamma curve buffer, 0x10000 * sizeof(uint16_t)
@property (nonatomic) uint16_t *gammaCurveBuf;

/// output size of the image; if rotation is applied, this is changed as needed.
@property (nonatomic) NSSize outputSize;

/// pixel format converter (may be shared/re-used)
@property (nonatomic) TSPixelConverterRef converter;

/// completion callback
@property (nonatomic) TSRawPipelineCompletionCallback completionCallback;
/// progress callback
@property (nonatomic) TSRawPipelineProgressCallback progressCallback;

/// when yes, lens corrections will be applied
@property (nonatomic) BOOL applyLensCorrections;
/// lens for which correction is applied
@property (nonatomic) lfLens *lcLens;
/// image modifier for lens corrections, based on the above lens
@property (nonatomic) lfModifier *lcModifier;

/// Initial CIImage; passed to the first filter.
@property (nonatomic) CIImage *coreImageInput;
/// final image
@property (nonatomic, weak) NSImage *result;

/**
 * Adds an operation to the list of operations associated with the op.
 */
-(void) addOperation:(NSOperation *) op;

/**
 * Executes the success callback with the given image.
 */
- (void) completeWithImage:(NSImage *) image;

/**
 * Terminates the RAW pipeline with an error message.
 */
- (void) terminateWithError:(NSError *) err;

@end
