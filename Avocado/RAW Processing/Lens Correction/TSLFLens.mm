//
//  TSLFLens.mm
//  Avocado
//
//  Created by Tristan Seifert on 20160526.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLFLens.h"

#import "lensfun.h"

@interface TSLFLens ()

@property (nonatomic) lfLens *lens;

@end

@implementation TSLFLens

/**
 * Creates a lens object.
 */
- (instancetype) initWithLens:(void *) lens {
	if(self = [super init]) {
		self.lens = (lfLens *) lens;
	}
	
	return self;
}

@end
