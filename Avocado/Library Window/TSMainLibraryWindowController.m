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

#import "TSHistogramView.h"

#import <QuartzCore/QuartzCore.h>

@interface TSMainLibraryWindowController ()

@property (nonatomic) TSLibraryOverviewController *vcOverview;
@property (nonatomic) TSLibraryDetailController *vcEdit;

@property (nonatomic, readonly) NSURL *savedStateFileUrl;

- (void) activateViewController:(TSMainLibraryContentViewController *) vc animated:(BOOL) isAnimated;

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
	self.vcOverview.windowController = self;
	self.vcOverview.view;
	
	self.vcEdit = [[TSLibraryDetailController alloc] initWithNibName:@"TSLibraryDetail" bundle:nil];
	self.vcEdit.windowController = self;
	self.vcEdit.view;
	
	self.window.backgroundColor = [NSColor blackColor];
	
	// set the initial view controller
	[self activateViewController:self.vcOverview animated:NO];
	
	// load restorable state
	[self readStateFromDisk];
}

#pragma mark Helpers
/**
 * Activates the given view controller.
 */
- (void) activateViewController:(TSMainLibraryContentViewController *) vc animated:(BOOL) isAnimated {
	// save the current rect
	NSRect oldFrame = self.window.frame;
	
	if(isAnimated) {
		DDLogVerbose(@"Began fade out");
		
		// animate all the things
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
			// set up context
			ctx.duration = 0.175;
			ctx.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			// animate
			self.window.contentViewController.view.animator.alphaValue = 0.f;
			
			// prepare window for appearance
			[vc prepareWindowForAppearance:self.window];
			self.window.toolbar = vc.windowToolbar;
		} completionHandler:^{
			DDLogVerbose(@"Began fade in");
			
			// set the new VC
			vc.view.alphaValue = 0.f;
			self.window.contentViewController = vc;
			
			// update window frame
			[self.window setFrame:oldFrame display:YES];
			
			// animate in the alpha of the view controller
			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
				// set up context
				ctx.duration = 0.175;
				ctx.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
				
				vc.view.animator.alphaValue = 1.f;
			} completionHandler:^{
				DDLogVerbose(@"Complete fade in");
			}];
		}];
	} else {
		[vc prepareWindowForAppearance:self.window];
		self.window.toolbar = vc.windowToolbar;
		
		vc.view.alphaValue = 1.f;
		self.window.contentViewController = vc;
		
		// update window's frame
		[self.window setFrame:oldFrame display:YES];
	}
}

/**
 * Sets the editing/detail controller as the content view controller, then
 * loads the specified image into it.
 */
- (void) openEditorForImage:(TSLibraryImage *) image {
	self.vcEdit.image = image;
	
	// actually present the view controller
	[self activateViewController:self.vcEdit animated:YES];
}

/**
 * Switches to the light table view.
 */
- (void) openLightTable {
	[self activateViewController:self.vcOverview animated:YES];
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

- (IBAction) loadHistoImage:(id) sender {
	CIImage *im = [CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:@"/Users/tristan/Library/Application Support/me.tseifert.Avocado/Photos/2016-03-20/WHS_0119.JPG"]];
	self.histo.image = im;
}

@end
