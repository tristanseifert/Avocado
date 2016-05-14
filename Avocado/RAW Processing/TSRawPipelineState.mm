//
//  TSRawPipelineState.m
//  Avocado
//
//  Created by Tristan Seifert on 20160504.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSRawPipelineState.h"

void *TSStageKVOCtx = &TSStageKVOCtx;

@interface TSRawPipelineState ()

/// All operations associated with this invocation of the pipeline.
@property (nonatomic) NSMutableSet<NSOperation *> *operations;

@end

@implementation TSRawPipelineState

/**
 * Initializes the pipeline state, allocating some data structures.
 */
- (instancetype) init {
	if(self = [super init]) {
		self.operations = [NSMutableSet new];
		
		[self addObserver:self forKeyPath:@"stage" options:0 context:&TSStageKVOCtx];
	}
	
	return self;
}

/**
 * Cleans up some stuff.
 */
- (void) dealloc {
	@try {
		[self removeObserver:self forKeyPath:@"stage"];
	} @catch (NSException __unused *exception) { }
}

/**
 * Handles KVO for the stage parameter.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath
					   ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	// is it the KVO handler for the stage?
	if(context == TSStageKVOCtx) {
		// if so, execute the progress callback, if specified.
		if(self.progressCallback) {
			self.progressCallback(self.stage);
		}
	}
}

/**
 * Executes the success callback with the given image.
 */
- (void) completeWithImage:(NSImage *) image {
	self.completionCallback(image, nil);
}

/**
 * Adds an operation to the list of operations associated with the op.
 */
-(void) addOperation:(NSOperation *) op {
	[self.operations addObject:op];
}

/**
 * Terminates the RAW pipeline with an error message.
 *
 * @param err Error message; this is passed to the completion callback provided
 * by the user.
 *
 * @note All operations (which have not started yet) will be canceled before
 * running the completion handler.
 */
- (void) terminateWithError:(NSError *) err {
	// cancel all operations
	[self.operations enumerateObjectsUsingBlock:^(NSOperation *op, BOOL *stop) {
		// has the operation completed?
		if(op.isFinished == NO) {
			// cancel operation
			[op cancel];
		}
	}];
	
	// run the cancel handler
	self.completionCallback(nil, err);
}

@end
