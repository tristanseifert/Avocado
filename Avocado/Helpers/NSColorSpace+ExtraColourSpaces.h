//
//  NSColorSpace+ExtraColourSpaces.h
//  Avocado
//
//  Created by Tristan Seifert on 20160508.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColorSpace (ExtraColourSpaces)

/**
 * Returns a colour space object, initialized with an embedded ProPhoto
 * RGB ICC profile.
 */
+ (instancetype) proPhotoRGBColorSpace;

@end
