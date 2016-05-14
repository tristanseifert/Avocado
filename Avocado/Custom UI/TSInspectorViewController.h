//
//  TSInspectorView.h
//  Avocado
//
//	This is an object that controls a stack view, which is used to display
//	a series of stacked inspectors.
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSInspectorViewItem.h"

@interface TSInspectorViewController : NSObject

/**
 * Appends an inspector to the end of the view.
 */
- (void) addInspectorView:(TSInspectorViewItem *) controller;

/**
 * Inserts an inspector view at the given index.
 */
- (void) insertInspectorView:(TSInspectorViewItem *) controller atIndex:(NSUInteger) index;

/**
 * Removes a previously added inspector view.
 */
- (void) removeInspectorView:(TSInspectorViewItem *) controller;

@end
