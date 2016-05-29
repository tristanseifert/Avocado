//
//  TSThumbHandlerDelegate.h
//  Avocado
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Callers of the thumb handler (i.e. the main app) should implement this
 * protocol, then export themselves to the other end of the connection, so that
 * they can be notified when a thumbnail operation has completed.
 */
@protocol TSThumbHandlerDelegate <NSObject>

/**
 * When the thumbnail generation completes successfully for an image previously
 * requested, this callback is executed.
 *
 * @param identifier Value passed to fetchThumbForImage:isUrgent:withIdentifier:
 * @param url Url of the thumbnail image.
 */
- (void) thumbnailGeneratedForIdentifier:(NSString *) identifier atUrl:(NSURL *) url;

/**
 * If an unexpected error occurs during thumbnail processing (i.e. the file is
 * unreadable, or the raw image does not contain a valid thumbnail) this method
 * is called. If an error is available, it is passed in as well.
 *
 * @param identifier Value passed to fetchThumbForImage:isUrgent:withIdentifier:
 * @param error An `NSError` object describing the error, if applicable.
 */
- (void) thumbnailFailedForIdentifier:(NSString *) identifier withError:(NSError *) error;

@end
