//
//  TSMainLibraryContentViewController.h
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSMainLibraryContentViewController : NSViewController

/**
 * Prepares the given window to host this view controller.
 */
- (void) prepareWindowForAppearance:(NSWindow *) window;

/**
 * Saves any view options. Keys should be prefixed by some unique value.
 */
- (void) saveViewOptions:(NSKeyedArchiver *) archiver;

/**
 * Restores view options. Keys should be prefixed by some unique value.
 */
- (void) restoreViewOptions:(NSKeyedUnarchiver *) unArchiver;

@end
