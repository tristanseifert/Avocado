//
//  NSBlockOperation+AvocadoUtils.h
//  Avocado
//
//  Created by Tristan Seifert on 20160506.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBlockOperation (AvocadoUtils)

/**
 * Creates a block operation, passing a pointer to the operation in the
 * block.
 */
+ (_Nullable instancetype) operationWithBlock:(void (^_Nonnull)(NSBlockOperation * _Nonnull)) block;

@end
