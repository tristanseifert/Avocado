//
//  NSBezierPath+AvocadoUtils.m
//  Avocado
//
//  Created by Tristan Seifert on 20160509.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "NSBezierPath+AvocadoUtils.h"

@implementation NSBezierPath (AvocadoUtils)

/**
 * Produces a smooth, Hermite-interpolated curve between the first point
 * and all successive points; this is then appended to the existing path.
 *
 * @param points Array of NSPoint values, wrapped in NSValue.
 */
- (void) interpolatePointsWithHermite:(NSArray<NSValue *> *) points {
	NSInteger n = points.count - 1;
	
	for(NSInteger ii = 0; ii < n; ++ii) {
		NSPoint currentPoint = points[ii].pointValue;
		
		if(ii == 0) {
			[self moveToPoint:points[0].pointValue];
		}
		
		// calculate the first control point
		NSInteger nextii = (ii + 1) % points.count;
		NSInteger previi = ((ii - 1 < 0) ? points.count - 1 : ii-1);
		
		NSPoint previousPoint = points[previi].pointValue;
		NSPoint nextPoint = points[nextii].pointValue;
		NSPoint endPoint = nextPoint;
		
		CGFloat mx = 0.f;
		CGFloat my = 0.f;
		
		if(ii > 0) {
			mx = (nextPoint.x - currentPoint.x) * 0.5 + (currentPoint.x - previousPoint.x) * 0.5;
			my = (nextPoint.y - currentPoint.y) * 0.5 + (currentPoint.y - previousPoint.y) * 0.5;
		} else {
			mx = (nextPoint.x - currentPoint.x) * 0.5;
			my = (nextPoint.y - currentPoint.y) * 0.5;
		}
		
		NSPoint controlPoint1 = NSMakePoint(currentPoint.x + mx / 3.0,  currentPoint.y + my / 3.0);
		
		// calculate the second control point
		currentPoint = points[nextii].pointValue;
		nextii = (nextii + 1) % points.count;
		previi = ii;
		previousPoint = points[previi].pointValue;
		nextPoint = points[nextii].pointValue;
		
		if(ii < n - 1) {
			mx = (nextPoint.x - currentPoint.x) * 0.5 + (currentPoint.x - previousPoint.x) * 0.5;
			my = (nextPoint.y - currentPoint.y) * 0.5 + (currentPoint.y - previousPoint.y) * 0.5;
		} else {
			mx = (currentPoint.x - previousPoint.x) * 0.5;
			my = (currentPoint.y - previousPoint.y) * 0.5;
		}
		
		NSPoint controlPoint2 = NSMakePoint(currentPoint.x - mx / 3.0, currentPoint.y - my / 3.0);
		
		// add a curve to that point, with the two given control points
		[self curveToPoint:endPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
	}
}

/**
 * Creates a CoreGraphics path from this path.
 */
- (CGPathRef) quartzPath {
	NSInteger i, numElements;
	
	// Need to begin a path here.
	CGPathRef immutablePath = NULL;
	
	// Then draw the path elements.
	numElements = [self elementCount];
	if (numElements > 0) {
		CGMutablePathRef path = CGPathCreateMutable();
		NSPoint points[3];
		BOOL didClosePath = YES;
		
		for (i = 0; i < numElements; i++) {
			switch ([self elementAtIndex:i associatedPoints:points]) {
				case NSMoveToBezierPathElement:
					CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
					break;
					
				case NSLineToBezierPathElement:
					CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
					didClosePath = NO;
					break;
					
				case NSCurveToBezierPathElement:
					CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
										  points[1].x, points[1].y,
										  points[2].x, points[2].y);
					didClosePath = NO;
					break;
					
				case NSClosePathBezierPathElement:
					CGPathCloseSubpath(path);
					didClosePath = YES;
					break;
			}
		}
		
		// Be sure the path is closed or Quartz may not do valid hit detection.
		if (!didClosePath) {
			CGPathCloseSubpath(path);
		}
		
		immutablePath = CGPathCreateCopy(path);
		CGPathRelease(path);
	}
	
	return immutablePath;
}

@end
