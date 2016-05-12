//
//  NSColor+AvocadoUtils.h
//  Avocado
//
//  Created by Tristan Seifert on 20160512.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (AvocadoUtils)

/// hue of the colour
@property (nonatomic, readonly, getter=TSGetHue) CGFloat hue;
/// saturation of the colour
@property (nonatomic, readonly, getter=TSGetSaturation) CGFloat saturation;
/// brightness of the colour
@property (nonatomic, readonly, getter=TSGetBrightness) CGFloat brightness;

@end
