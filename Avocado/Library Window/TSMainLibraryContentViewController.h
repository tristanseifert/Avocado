//
//  TSMainLibraryContentViewController.h
//  Avocado
//
//	An abstract protocol that view controllers for the main window
//	implement.
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TSMainLibraryWindowController;
@protocol TSMainLibraryContentViewController <NSObject>

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

/// weak reference to the window controller
@property (nonatomic, weak) TSMainLibraryWindowController *windowController;
/// a toolbar that is displayed in the window, if desired
@property (nonatomic) IBOutlet NSToolbar *windowToolbar;

@end
