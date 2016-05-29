//
//  TSThumbCache.h
//  Avocado
//
//  Created by Tristan Seifert on 20160501.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSThumbHandlerDelegate.h"

typedef void (^TSThumbCacheCallback)(NSImage *);

@class TSLibraryImage;
@interface TSThumbCache : NSObject <TSThumbHandlerDelegate>

+ (instancetype) sharedInstance;

/**
 * Runs a thumb request for the given image, using the specified size. If the
 * image is cached already, the callback is run immediately and no further
 * action is performed.
 *
 * @note There is absolutely no guarantee as to which thread the callback is
 * executed on.
 *
 * @note The callback may be called more than once, with a more fitting
 * thumbnail each time.
 */
- (void) getThumbForImage:(TSLibraryImage *) inImage withSize:(NSSize) size andCallback:(TSThumbCacheCallback) callback;

@end
