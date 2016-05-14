//
//  TSInspectorView.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSInspectorView.h"

@implementation TSInspectorView

/**
 * Flips the coordinate system.
 */
- (BOOL) isFlipped {
	return YES;
}

/**
 * Allow for vibrant drawing.
 */
- (BOOL) allowsVibrancy {
	return YES;
}

@end
