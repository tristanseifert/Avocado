//
//  TSCoreDataStore.h
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSCoreDataStore : NSObject

- (void) cleanUp;

@property (nonatomic, readonly) NSURL *storeUrl;

@end
