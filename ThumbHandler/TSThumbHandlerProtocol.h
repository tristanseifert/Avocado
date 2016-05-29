//
//  TSThumbHandlerProtocol.h
//  ThumbHandler
//
//  Created by Tristan Seifert on 20160528.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

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
 * @param urgent If this parameter is set, it indicates that the user is most
 * likely waiting on the thumbnail (i.e. some list was scrolled, and thumbnails
 * need to be shown) and it should be given a higher priority.
 * @param completionIdentifier Passed as an argument to the delegate when the
 * thumbnail has been generated.
 */
- (void) fetchThumbForImage:(TSThumbImageProxy *) image isUrgent:(BOOL) urgent withIdentifier:(NSString *) completionIdentifier;
    
@end