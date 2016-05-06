//
//  NSBlockOperation+AvocadoUtils.m
//  Avocado
//
//  Created by Tristan Seifert on 20160506.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "NSBlockOperation+AvocadoUtils.h"

@implementation NSBlockOperation (AvocadoUtils)

/**
 * Creates a block operation, passing a pointer to the operation in the
 * block.
 */
+ (instancetype) operationWithBlock:(void (^_Nonnull)(NSBlockOperation *)) block {
	NSBlockOperation *op = [NSBlockOperation new];
	__weak __block NSBlockOperation *blockOp = op;
	
	// add the block
	[op addExecutionBlock:^{
		block(blockOp);
	}];
	
	return op;
}

@end
