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
 * Frees the internal lens object on deallocation.
 */
- (void) dealloc {
	delete self.lens;
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
 *
 * A display name might be "Canon 50mm ƒ/1.8" or "Canon 70-200mm ƒ/2.8 III"
 */
- (NSString *) displayName {
/*	if(self.focalMin == self.focalMax) {
		NSString *localizedString = NSLocalizedString(@"%@ %.0fmm ƒ/%2.1f %@", nil);
		return [NSString localizedStringWithFormat:localizedString, self.maker, self.focalMin, self.apertureMin, self.model];
	} else {
		NSString *localizedString = NSLocalizedString(@"%@ %.0f-%.0fmm ƒ/%2.1f %@", nil);
		return [NSString localizedStringWithFormat:localizedString, self.maker, self.focalMin, self.focalMax, self.apertureMin, self.model];
	}*/
	
	// Return the model, concatenated with the crop factor
	NSString *localizedString = NSLocalizedString(@"%@ (Crop %.2g)", nil);
	return [NSString localizedStringWithFormat:localizedString, self.model, self.lens->CropFactor];
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



/**
 * Returns a description for this camera, consisting of its address,
 */
- (NSString *) description {
	return [NSString stringWithFormat:@"TSLFLens<%p> maker = %@, model = %@, displayName = %@, score = %zi; focal range = %f - %f, aperture range = %f - %f", self, self.maker, self.model, self.displayName, self.sortingScore, self.focalMin, self.focalMax, self.apertureMin, self.apertureMax];
}

@end