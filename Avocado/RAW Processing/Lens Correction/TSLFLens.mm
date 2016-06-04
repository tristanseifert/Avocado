//
//  TSLFLens.mm
//  Avocado
//
//  Created by Tristan Seifert on 20160526.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLFLens.h"
#import "TSLFDatabase.h"

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

/**
 * Reads the maker string from the lens object.
 */
- (NSString *) maker {
	NSLocale *loc = [NSLocale currentLocale];
	return [TSLFDatabase stringForLocale:loc inLFString:self.lens->Maker];
}

/**
 * Reads the model string from the lens object.
 */
- (NSString *) model {
	NSLocale *loc = [NSLocale currentLocale];
	return [TSLFDatabase stringForLocale:loc inLFString:self.lens->Model];
}

/**
 * Puts together a lens display name (shown in the UI) from a variety of other
 * parameters.
 */
- (NSString *) displayName {
	// TODO: Implement this
	return nil;
}

/**
 *  Returns the sorting score of the lens.
 */
- (NSInteger) sortingScore {
	return self.lens->Score;
}


/**
 * Returns the focal length range of this lens.
 */
- (CGFloat) focalMin {
	return self.lens->MinFocal;
}

/**
 * Returns the focal length range of this lens.
 */
- (CGFloat) focalMax {
	return self.lens->MaxFocal;
}

/**
 * Returns the focal length range of this lens.
 */
- (CGFloat) apertureMin {
	return self.lens->MinAperture;
}

/**
 * Returns the focal length range of this lens.
 */
- (CGFloat) apertureMax {
	return self.lens->MaxAperture;
}

@end