//
//  NSColorSpace+ExtraColourSpaces.h
//  Avocado
//
//  Created by Tristan Seifert on 20160508.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/// ProPhoto RGB ICC profile
extern const uint8_t TSColourSpace_ProPhotoICC[];
/// Length of the ProPhoto RGB ICC profile data blob
extern const NSUInteger TSColourSpace_ProPhotoICC_Length;

@interface NSColorSpace (ExtraColourSpaces)

/**
 * Returns a colour space object, initialized with an embedded ProPhoto
 * RGB ICC profile.
 */
+ (instancetype) proPhotoRGBColorSpace;

@end
