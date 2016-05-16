//
//  TSBufferOwningBitmapRep.m
//  Avocado
//
//  Created by Tristan Seifert on 20160516.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSBufferOwningBitmapRep.h"

@implementation TSBufferOwningBitmapRep

/**
 * Frees all pointers that this image representation is associated with;
 * any subsequent accesses to the data will cause a crash.
 */
- (void) TSFreeBuffers {
	unsigned char *planes[5];
	[self getBitmapDataPlanes:planes];
	
	DDLogVerbose(@"Bitmap ptr = %p", self.bitmapData);
	
	for(NSUInteger i = 0; i < 5; i++) {
		if(planes[i] != nil) {
			DDLogVerbose(@"Freeing %p", planes[i]);
			free(planes[i]);
		}
	}
}

@end
