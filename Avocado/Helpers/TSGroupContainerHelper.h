//
//  TSGroupContainerHelper.h
//  Avocado
//
//	A small helper class that can return the URL of various group container
//	directories.
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSGroupContainerHelper : NSObject

+ (instancetype) sharedInstance;

/**
 * Root URL of the group container. This container is shared between the main
 * app, as well as any XPC services and helper apps.
 */
@property (nonatomic, readonly) NSURL *groupContainerRoot;

/// Application Support directory in group container
@property (nonatomic, readonly) NSURL *appSupport;
/// Caches directory in group container
@property (nonatomic, readonly) NSURL *caches;

@end
