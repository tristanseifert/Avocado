//
//  TSThumbCache.h
//  Avocado
//
//  Created by Tristan Seifert on 20160501.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSThumbHandlerDelegate.h"
#import "TSThumbHandlerProtocol.h"

/**
 * Thumbnail completion callback: the first parameter is an NSImage if the
 * conversion was successful, nil otherwise. The second parameter is the pointer
 * passed as `userData` earlier.
 */
typedef void (^TSThumbCacheCallback)(NSImage *, void *);

@class TSLibraryImage;
@interface TSThumbCache : NSObject <TSThumbHandlerDelegate>

+ (instancetype) sharedInstance;


/**
 * Runs a thumb request for the given image, using the specified size. If the
 * image is cached already, the callback is run immediately and no further
 * action is performed. It is assumed that the default priority is used.
 */
- (void) getThumbForImage:(TSLibraryImage *) inImage withSize:(NSSize) size andCallback:(TSThumbCacheCallback) callback withUserData:(void *) userData;

/**
 * Creates a thumbnail for the given size, at the specified size. If the image
 * has already been generated, and is in the cache, the callback is executed
 * immediately and the method returns.
 *
 * Otherwise, if the thumbnail is not in the cache, a request is made to the
 * XPC service to generate the thumbnail, and some information is stored so that
 * the callbacks can be executed when the image is produced.
 *
 * If this call is made multiple times, for the same image, before the XPC
 * service returns data, the callback is added to the existing request.
 *
 * @param inImage Input image, for which to generate the thumbnail
 * @param size Requested size; there is no guarantee that the image will be this
 * size; it is simply used as a hint in processing the image.
 * @param callback Callback to execute when the image is complete.
 * @param userData Pointer to arbitrary data passed to the callback.
 * @param priority Relative priority of the thumbnail request.
 */
- (void) getThumbForImage:(TSLibraryImage *) inImage withSize:(NSSize) size andCallback:(TSThumbCacheCallback) callback withUserData:(void *) userData andPriority:(TSThumbHandlerUrgency) priority;

/**
 * Pre-fills the cache by requesting that the XPC service generates a thumb for
 * a newly created image. This runs at the lowest priority possible.
 */
- (void) warmCacheWithThumbForImage:(TSLibraryImage *) inImage;

@end
