//
//  TSLFCamera.mm
//  Avocado
//
//  Created by Tristan Seifert on 20160526.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLFCamera.h"
#import "TSLFDatabase.h"

#import "lensfun.h"

@interface TSLFCamera ()

@property (nonatomic) lfCamera *camera;

@end

@implementation TSLFCamera

/**
 * Creates a camera object.
 */
- (instancetype) initWithCamera:(void *) camera {
	if(self = [super init]) {
		self.camera = (lfCamera *) camera;
	}
	
	return self;
}

/**
 * Reads the maker string from the camera object.
 */
- (NSString *) maker {
	NSLocale *loc = [NSLocale currentLocale];
	return [TSLFDatabase stringForLocale:loc inLFString:self.camera->Maker];
}

/**
 * Reads the model string from the camera object.
 */
- (NSString *) model {
	NSLocale *loc = [NSLocale currentLocale];
	return [TSLFDatabase stringForLocale:loc inLFString:self.camera->Model];
}

@end
