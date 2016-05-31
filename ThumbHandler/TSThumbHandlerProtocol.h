//
//  TSThumbHandlerProtocol.h
//  ThumbHandler
//
//  Created by Tristan Seifert on 20160528.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Maximum size of a thumbnail, on the long edge
static const CGFloat TSThumbMaxSize = 1024.f;

/**
 * Defines varying levels of urgency for thumbnail generation.
 */
typedef NS_ENUM(NSUInteger, TSThumbHandlerUrgency) {
	/**
	 * Indicates that the thumbnail should be generated with the lowest priority
	 * possible. This causes them to run on a separate queue with a very low
	 * quality of service. This might be used when importing images.
	 */
	kTSThumbHandlerBackground = 0x10,
	
	/**
	 * Default urgency. Request occurs on a slightly higher priority queue.
	 */
	kTSThumbHandlerDefault = 0x20,
	/**
	 * High urgency. This causes the operation to get a boosted quality of
	 * service. This could be used when a table cell came on-screen, and no
	 * thumbnail information has been loaded yet.
	 */
	kTSTHumbHandlerUrgent = 0x30,
};

@class TSThumbImageProxy;

/**
 * Methods defined in this protocol are implemented by the thumbnail handler
 * XPC service.
 */
@protocol TSThumbHandlerProtocol

/**
 * Requests that a thumbnail is generated for the given image. If the thumbnail
 * does not exist, it will be created and stored on-disk. Otherwise, the path
 * to the image is fetched from the database and returned.
 *
 * @param image An image object, containing some pertinent information about it.
 * @param urgent Determines the relative priority of the request.
 * @param completionIdentifier Passed as an argument to the delegate when the
 * thumbnail has been generated.
 */
- (void) fetchThumbForImage:(TSThumbImageProxy *) image withPriority:(TSThumbHandlerUrgency) priority andIdentifier:(NSString *) completionIdentifier;

/**
 * Resets the contents of the cache. All objects are deleted from the persistent
 * store, and the files are removed from disk.
 *
 * If an error occurred during the deletion of thumbnails, the reply block is
 * called with a non-nil error object. Otherwise, it is nil.
 */
- (void) deleteAllThumbsWithReply:(void (^)(NSError *)) reply;

/**
 * Calculates the size of the cache on disk.
 */
- (void) calculateCacheDiskSize:(void (^)(NSUInteger)) reply;

@end