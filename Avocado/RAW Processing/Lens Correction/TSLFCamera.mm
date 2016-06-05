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
 * Frees the internal camera object on deallocation.
 */
- (void) dealloc {
	delete self.camera;
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

/**
 * Puts together a camera display name (shown in the UI) from a variety of other
 * parameters.
 */
- (NSString *) displayName {
	NSString *localizedString = NSLocalizedString(@"%@ %@", @"Camera display name; 1 = maker, 2 = model");
	return [NSString localizedStringWithFormat:localizedString, self.maker, self.model];
}


/**
 * Returns a description for this camera, consisting of its address,
 */
- (NSString *) description {
	return [NSString stringWithFormat:@"TSLFCamera<%p> maker = %@, model = %@", self, self.maker, self.model];
}

@end
