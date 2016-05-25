//
//  AppDelegate.m
//  Avocado
//
//  Created by Tristan Seifert on 20160428.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSAppDelegate.h"

#import "TSMainLibraryWindowController.h"
#import "TSCoreDataStore.h"

@interface TSAppDelegate ()

// secret CoreData store
@property (nonatomic) TSCoreDataStore *store;

@end

@implementation TSAppDelegate

/**
 * Sets up any initial app state, as the app is about to finish launching.
 */
- (void) applicationWillFinishLaunching:(NSNotification *) notification {
	// register user defaults
	NSURL *defaultsUrl = [[NSBundle mainBundle] URLForResource:@"TSDefaultSettings" withExtension:@"plist"];
	NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:defaultsUrl];
	DDAssert(defaults != nil, @"Defaults may not be nil; loaded from %@", defaultsUrl);
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

/**
 * Does some magic things when the app finishes launching, then sets up the
 * main window.
 */
- (void) applicationDidFinishLaunching:(NSNotification *) aNotification {
	// set up the coredata stack, via MagicalRecord™
	self.store = [TSCoreDataStore new];
	
	// create the window controller
	self.mainWindow = [[TSMainLibraryWindowController alloc] initWithWindowNibName:@"TSMainLibraryWindow"];
	[self.mainWindow showWindow:NSApp];
}

/**
 * Closes down any remaining resources.
 */
- (void) applicationWillTerminate:(NSNotification *) aNotification {
	// clean up stack
	[self.store cleanUp];
}

/**
 * Cause the app to terminate once the last window closes.
 */
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) app {
	return YES;
}

@end
