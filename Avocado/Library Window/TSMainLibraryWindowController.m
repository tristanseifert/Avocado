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
#import "TSHumanModels.h"

#import "TSHistogramView.h"

#import <MagicalRecord/MagicalRecord.h>
#import <QuartzCore/QuartzCore.h>

@interface TSMainLibraryWindowController ()

@property (nonatomic) TSLibraryOverviewController *vcOverview;
@property (nonatomic) TSLibraryDetailController *vcEdit;

@property (nonatomic, readonly) NSURL *savedStateFileUrl;

/// index of the currently active view controller
@property (nonatomic) NSUInteger activeVC;
/// URL of the image that was last open in the develop view
@property (nonatomic) NSURL *lastDevelopImage;

- (void) appWillTerminate:(NSNotification *) notification;

- (void) activateViewController:(NSViewController <TSMainLibraryContentViewController> *) vc animated:(BOOL) isAnimated;

- (void) readWindowState:(NSKeyedUnarchiver *) archiver;
- (void) saveWindowState:(NSKeyedArchiver *) archiver;

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
	self.vcOverview = [[TSLibraryOverviewController alloc] init];
	self.vcOverview.windowController = self;
	
	self.vcEdit = [[TSLibraryDetailController alloc] init];
	self.vcEdit.windowController = self;
	
	
	self.window.backgroundColor = [NSColor blackColor];
	
	// load restorable state
	[self readStateFromDisk];
	
	// do the thing
	NSArray<TSLibraryImage *> *all = [TSLibraryImage MR_findAll];
	
	[all enumerateObjectsUsingBlock:^(TSLibraryImage *mainIm, NSUInteger idx, BOOL *stop) {
//		[MagicalRecord saveWithBlock:^(NSManagedObjectContext *ctx) {
//			TSLibraryImage *im = [mainIm MR_inContext:ctx];
//			
//			im.uuid = [NSUUID new].UUIDString;
//			[im loadDefaultAdjustments];
//		}];
		
		DDLogDebug(@"Data for %p: %@ %@", mainIm, mainIm.adjustments, mainIm.rawAdjustmentData);
	}];
	
	// figure out what view controller to show
	switch(self.activeVC) {
		// light table
		case 0:
			[self activateViewController:self.vcOverview animated:NO];
			break;
			
		// develop/edit view
		case 1:
			if(self.lastDevelopImage != nil) {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSError *err = nil;
					NSPersistentStoreCoordinator *psc;
					NSManagedObjectContext *ctx;
					NSManagedObjectID *oid;
					
					// get an object from the url
					ctx = [NSManagedObjectContext MR_defaultContext];
					psc = ctx.persistentStoreCoordinator;
					
					oid = [psc managedObjectIDForURIRepresentation:self.lastDevelopImage];
					
					TSLibraryImage *im = [ctx existingObjectWithID:oid error:&err];
					
					// set the image
					if(im && err == nil) {
						[self activateViewController:self.vcEdit animated:NO];
						
						self.vcEdit.image = im;
					} else {
						DDLogError(@"Couldn't unarchive image with URI %@: %@", self.lastDevelopImage, err);
						
						[self activateViewController:self.vcOverview animated:NO];
					}
				});
			} else {
				DDLogWarn(@"Tried to switch to develop view, but have no last develop image…");
				[self activateViewController:self.vcOverview animated:NO];
			}
			break;
	}
	
	// add notifications
	NSNotificationCenter *c = [NSNotificationCenter defaultCenter];
	
	[c addObserver:self selector:@selector(appWillTerminate:)
			  name:NSApplicationWillTerminateNotification object:nil];
}

/**
 * Cleans up some state when deallocating.
 */
- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Helpers
/**
 * Activates the given view controller.
 */
- (void) activateViewController:(NSViewController <TSMainLibraryContentViewController> *) vc animated:(BOOL) isAnimated {
	// save the current rect
	NSRect oldFrame = self.window.frame;
	
	if(isAnimated) {
//		DDLogVerbose(@"Began fade out");
		
		// animate all the things
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
			// set up context
			ctx.duration = 0.175;
			ctx.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			
			// animate
			self.window.contentViewController.view.animator.alphaValue = 0.f;
		} completionHandler:^{
//			DDLogVerbose(@"Began fade in");
			
			// set the new VC
			vc.view.alphaValue = 0.f;
			self.window.contentViewController = vc;
			
			// prepare window for appearance
			[vc prepareWindowForAppearance:self.window];
			self.window.toolbar = vc.windowToolbar;
			
			// update window frame
			[self.window setFrame:oldFrame display:YES];
			
			// animate in the alpha of the view controller
			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
				// set up context
				ctx.duration = 0.175;
				ctx.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
				
				vc.view.animator.alphaValue = 1.f;
			} completionHandler:^{
//				DDLogVerbose(@"Complete fade in");
			}];
		}];
	} else {
		vc.view.alphaValue = 1.f;
		self.window.contentViewController = vc;
		
		[vc prepareWindowForAppearance:self.window];
		self.window.toolbar = vc.windowToolbar;
		
		// update window's frame
		[self.window setFrame:oldFrame display:YES];
	}
	
	// update the value for the current view controller
	if(vc == self.vcOverview)
		self.activeVC = 0;
	else if(vc == self.vcEdit)
		self.activeVC = 1;
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

/**
 * The application is about to terminate, so save restorable state.
 */
- (void) appWillTerminate:(NSNotification *) notification {
	[self saveStateToDisk];
}

#pragma mark State Handling
/**
 * Restores the window's state.
 */
- (void) readWindowState:(NSKeyedUnarchiver *) archiver {
	// restore selected view controller
	self.activeVC = [archiver decodeIntegerForKey:@"MainWindow.ActiveVC"];
	
	self.lastDevelopImage = [archiver decodeObjectOfClass:[NSURL class]
												   forKey:@"MainWindow.LastDevelopImage"];
}

/**
 * Saves the window's state.
 */
- (void) saveWindowState:(NSKeyedArchiver *) archiver {
	[archiver encodeInteger:self.activeVC forKey:@"MainWindow.ActiveVC"];
	
	// save the CoreData id of the image that was last being edited
	NSURL *lastEditedImg = self.vcEdit.image.objectID.URIRepresentation;
	[archiver encodeObject:lastEditedImg forKey:@"MainWindow.LastDevelopImage"];
}

/**
 * State restoration: opens the ControllerState file, and allows each view
 * controller to decode its state.
 */
- (void) readStateFromDisk {
	NSError *err = nil;
	
	// set up the unarchiver
	NSData *data = [NSData dataWithContentsOfURL:self.savedStateFileUrl options:0 error:&err];
	
	if(data == nil || err) {
		DDLogWarn(@"Error reading restorable state: %@; resetting to defaults", err);
		
		// load defaults
		NSURL *url = [[NSBundle mainBundle] URLForResource:@"TSDefaultAppState"
											 withExtension:@"plist"];
		data = [NSData dataWithContentsOfURL:url];
	}
	
	// construct archiver
	NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	
	archiver.requiresSecureCoding = YES;
	
	// load each controller's state
	[self.vcOverview restoreViewOptions:archiver];
	[self.vcEdit restoreViewOptions:archiver];
	
	// restore window state
	[self readWindowState:archiver];
	
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
	
	// save window state
	[self saveWindowState:archiver];
	
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
