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
	CGFloat alpha = 1.f / 3.f;
	
	if(points.count == 0) {
		return;
	}
	
	// move to the first point in the path
	[self moveToPoint:points.firstObject.pointValue];
	
	NSInteger n = points.count - 1;
	
	for(NSInteger index = 0; index < n; index++) {
		// calculate first control point
		NSPoint currentPoint = points[index].pointValue;
		NSInteger nextIndex = (index + 1) % points.count;
		NSInteger prevIndex = index == 0 ? points.count - 1 : index - 1;
	
		NSPoint previousPoint = points[prevIndex].pointValue;
		NSPoint nextPoint = points[nextIndex].pointValue;
		
		NSPoint endPoint = nextPoint;
		CGFloat mx = 0.f;
		CGFloat my = 0.f;
		
		if(index > 0) {
			mx = (nextPoint.x - previousPoint.x) / 2.f;
			my = (nextPoint.y - previousPoint.y) / 2.f;
		} else {
			mx = (nextPoint.x - currentPoint.x) / 2.f;
			my = (nextPoint.y - currentPoint.y) / 2.f;
		}
		
		NSPoint controlPoint1 = NSMakePoint(currentPoint.x + mx * alpha, currentPoint.y + my * alpha);
		
		// calculate second control point
		currentPoint = points[nextIndex].pointValue;
		nextIndex = (nextIndex + 1) % points.count;
		prevIndex = index;
		
		previousPoint = points[prevIndex].pointValue;
		nextPoint = points[nextIndex].pointValue;
		
		if(index < (n - 1)) {
			mx = (nextPoint.x - previousPoint.x) / 2.f;
			my = (nextPoint.y - previousPoint.y) / 2.f;
		} else {
			mx = (currentPoint.x - previousPoint.x) / 2.f;
			my = (currentPoint.y - previousPoint.y) / 2.f;
		}
		
		NSPoint controlPoint2 = NSMakePoint(currentPoint.x - mx * alpha, currentPoint.y - my * alpha);
		
		// add the curve
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
