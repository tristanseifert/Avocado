//
//  TSMainLibraryWindowController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSMainLibraryWindowController.h"

#import "TSLibraryOverviewController.h"
#import "TSLibraryDetailController.h"

@interface TSMainLibraryWindowController ()

@property (nonatomic) TSLibraryOverviewController *vcOverview;
@property (nonatomic) TSLibraryDetailController *vcEdit;

@property (nonatomic, readonly) NSURL *savedStateFileUrl;

- (void) readStateFromDisk;
- (void) saveStateToDisk;

@end

@implementation TSMainLibraryWindowController

/**
 * Applies some customizations to the window style.
 */
- (void) windowDidLoad {
    [super windowDidLoad];
	
	// create the various controllers
	self.vcOverview = [[TSLibraryOverviewController alloc] initWithNibName:@"TSLibraryOverview" bundle:nil];
	self.vcEdit = [[TSLibraryDetailController alloc] initWithNibName:@"TSLibraryDetail" bundle:nil];
	
	// set content
	self.contentViewController = self.vcOverview;
	
	[((TSMainLibraryContentViewController *) self.contentViewController) prepareWindowForAppearance:self.window];
	
	// load restorable state
	[self readStateFromDisk];
}

#pragma mark Window Delegate
/**
 * The window resigned key status, so save restorable state.
 */
- (void) windowDidResignKey:(NSNotification *) notification {
	[self saveStateToDisk];
}

/**
 * The window will close, so save restorable state.
 */
- (void) windowWillClose:(NSNotification *) notification {
	[self saveStateToDisk];
}

#pragma mark State Handling
/**
 * State restoration: opens the ControllerState file, and allows each view
 * controller to decode its state.
 */
- (void) readStateFromDisk {
	NSError *err = nil;
	
	// set up the unarchiver
	NSData *data = [NSData dataWithContentsOfURL:self.savedStateFileUrl options:0 error:&err];
	
	if(data == nil || err) {
		DDLogWarn(@"Error reading restorable state: %@", err);
		return;
	}
	
	// construct archiver
	NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	
	archiver.requiresSecureCoding = YES;
	
	// load each controller's state
	[self.vcOverview restoreViewOptions:archiver];
	[self.vcEdit restoreViewOptions:archiver];
	
	// finish
	[archiver finishDecoding];
}

/**
 * Saves each view controller's state, in response to the window becoming
 * inactive, or closing.
 */
- (void) saveStateToDisk {
	NSError *err = nil;
	
	// set up the archiver
	NSMutableData *data = [NSMutableData new];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	
	archiver.requiresSecureCoding = YES;
	
	// save each controller's state
	[self.vcOverview saveViewOptions:archiver];
	[self.vcEdit saveViewOptions:archiver];
	
	// save the data
	[archiver finishEncoding];
	[data writeToURL:self.savedStateFileUrl options:NSDataWritingAtomic
			   error:&err];
	
	if(err) {
		DDLogError(@"Error saving restorable state: %@", err);
		[NSApp presentError:err];
	}
}

/**
 * Returns the url for the saved state file. It's in the Application Support
 * directory.
 */
- (NSURL *) savedStateFileUrl {
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// get the directory pls
	NSURL *appSupportURL = [[fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	appSupportURL = [appSupportURL URLByAppendingPathComponent:@"me.tseifert.Avocado"];
	
	return [appSupportURL URLByAppendingPathComponent:@"ViewState.plist" isDirectory:NO];
}

@end
