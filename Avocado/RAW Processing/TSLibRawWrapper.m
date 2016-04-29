//
//  TSLibRawWrapper.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibRawWrapper.h"

#import "libraw.h"

@interface TSLibRawWrapper ()

@property (nonatomic) LibRaw *libRaw;

@end

@implementation TSLibRawWrapper

/**
 * Initializes the library.
 */
- (instancetype) init {
	if(self = [super init]) {
		// init libraw
		self.libRaw = new LibRaw();
	}
	
	return self;
}

/**
 * Loads the given RAW file.
 */
- (BOOL) loadFile:(NSURL *) url {
	int err = 0;
	
	// open the file, pls
	NSString *string = url.path;
	
	if((err = self.libRaw->open_file(string.fileSystemRepresentation)) != 0) {
		DDLogError(@"Error opening RAW file: %i", err);
		return NO;
	}
	
	
}

@end
