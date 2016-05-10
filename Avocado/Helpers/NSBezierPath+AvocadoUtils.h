//
//  NSBezierPath+AvocadoUtils.h
//  Avocado
//
//  Created by Tristan Seifert on 20160509.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSBezierPath (AvocadoUtils)

/**
 * Produces a smooth, Hermite-interpolated curve between the first point
 * and all successive points; this is then appended to the existing path.
 *
 * @param points Array of NSPoint values, wrapped in NSValue.
 */
- (void) interpolatePointsWithHermite:(NSArray<NSValue *> *) points;

/// CoreGraphics path
@property (nonatomic, readonly, getter=quartzPath) CGPathRef CGPath;

@end
