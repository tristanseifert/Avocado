//
//  TSBufferOwningBitmapRep.h
//  Avocado
//
//  Created by Tristan Seifert on 20160516.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSBufferOwningBitmapRep : NSBitmapImageRep

/**
 * Frees all pointers that this image representation is associated with;
 * any subsequent accesses to the data will cause a crash.
 */
- (void) TSFreeBuffers;

@end
