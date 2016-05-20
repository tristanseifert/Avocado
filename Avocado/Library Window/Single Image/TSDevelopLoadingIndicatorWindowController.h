//
//  TSDevelopLoadingIndicatorWindowController.h
//  Avocado
//
//	A small window that shows a message, as well as a loading indicator,
//	over a vibrant background. It is drawn with a 1pt dark stroke, and
//	does not render a drop shadow.
//
//	This window should be added as a child window for the window on which
//	the indicator is to be displayed. To show the indicator, simply make
//	the window front; to hide it, close it.
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSDevelopLoadingIndicatorWindowController : NSWindowController

/// string to show in the UI
@property (nonatomic) NSString *loadingString;

/**
 * Shows the window.
 */
- (void) showLoadingWindowInView:(NSView *) view withAnimation:(BOOL) animation;

/**
 * Hides the window.
 */
- (void) hideLoadingWindowWithAnimation:(BOOL) animation;

@end
