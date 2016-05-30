//
//  TSThumbHandler.h
//  ThumbHandler
//
//  Created by Tristan Seifert on 20160528.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSThumbHandlerProtocol.h"
#import "TSThumbHandlerDelegate.h"

@class NSManagedObjectContext;
@interface TSThumbHandler : NSObject <TSThumbHandlerProtocol>

/**
 * Sets up a few things upon initialization; namely, the CoreData store in which
 * all the thumbnail metadata is stored, as well as the thumbnail generation
 * queue and the on-disk cache structure.
 *
 * @param remote Object exported by the remote end of the XPC connectionl; this
 * object receives all notifications about completed thumb operations.
 * @param parentCtx Parent managed object context, associated with a persistent
 * store on disk.
 */
- (instancetype) initWithRemote:(id<TSThumbHandlerDelegate>) remote andContext:(NSManagedObjectContext *) parentCtx;

@end
