//
//  TSLensCorrectionInspector.m
//  Avocado
//
//  Created by Tristan Seifert on 20160604.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLensCorrectionInspector.h"

#import "TSHumanModels.h"
#import "TSCoreDataStore.h"
#import "TSLFDatabase.h"

static void *TSActiveImageKVOCtx = &TSActiveImageKVOCtx;
static void *TSSettingsKVOCtx = &TSSettingsKVOCtx;

/// Delay between invocations of change that must pass to re-render image
static const NSTimeInterval TSSettingsChangeDebounce = 0.66f;


@interface TSLensCorrectionInspector ()

/// When set, any changes to the image properties are ignored
@property (nonatomic) BOOL ignoreChanges;

@property (nonatomic, readwrite) NSArray<TSLFCamera *> *suitableCameras;
@property (nonatomic, readwrite) NSArray<TSLFLens *> *suitableLenses;

- (void) loadAdjustmentData;
- (void) saveAdjustmentData:(TSLibraryImage *) im;

- (void) addAdjustmentKVO;
- (void) removeAdjustmentKVO;

- (void) settingsChanged;
- (void) saveAfterSettingsChange;

- (void) findMatchingCameraLensCombinations;

@end

@implementation TSLensCorrectionInspector

- (instancetype) init {
	if(self = [super initWithNibName:@"TSLensCorrectionInspector" bundle:nil]) {
		self.title = NSLocalizedString(@"Lens Corrections", @"lens corrections inspector title");
		self.preferredContentSize = NSMakeSize(0, 86);
		
		// Add some KVO observers
		[self addObserver:self forKeyPath:@"activeImage"
				  options:0 context:TSActiveImageKVOCtx];
		
		self.ignoreChanges = YES;
		[self addAdjustmentKVO];
		
		// Set some default values
		self.correctionsEnabled = @(YES);
		self.isSelectionAllowed = @(YES);
	}
	
	return self;
}

/**
 * Performs some cleanup on deallocation.
 */
- (void) dealloc {
	[self removeAdjustmentKVO];
}

/**
 * Observes KVO.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	// Image changed
	if(context == TSActiveImageKVOCtx) {
		// Cancel last invocation for settings change
		[[self class] cancelPreviousPerformRequestsWithTarget:self
													 selector:@selector(saveAfterSettingsChange)
													   object:nil];
		
		// Copy the image adjustments
		if(self.activeImage) {
			[self loadAdjustmentData];
		}
		
		// Populate a list of cameras and lenses that could work
		[self findMatchingCameraLensCombinations];
	}
	// Settings changed
	else if(context == TSSettingsKVOCtx) {
		if(self.ignoreChanges == NO) {
			[self settingsChanged];
		}
	}
	// anything else
	else {
		[super observeValueForKeyPath:keyPath ofObject:object
							   change:change context:context];
	}
}

/**
 * Handles the settings changing; this will do a bit of debouncing to
 * reduce the number of times that the "change" method is run.
 */
- (void) settingsChanged {
	// Cancel previous invocations
	[[self class] cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(saveAfterSettingsChange)
												   object:nil];
	
	// Invoke after delay
	[self performSelector:@selector(saveAfterSettingsChange)
			   withObject:nil afterDelay:TSSettingsChangeDebounce];
}

#pragma mark Lens Database Handling
/**
 * Finds all matching lens and camera combinations for the given image.
 */
- (void) findMatchingCameraLensCombinations {
	self.ignoreChanges = YES;
	
	// If there's no active image, return.
	if(self.activeImage == nil) {
		self.suitableCameras = nil;
		self.suitableLenses = nil;
		
		return;
	}
	
	// Find cameras
	TSLFCamera *cam = [[TSLFDatabase sharedInstance] cameraForImage:self.activeImage];
	DDLogVerbose(@"Camera: %@", cam);
	
	if(cam != nil) {
		self.suitableCameras = @[cam];
	} else {
		self.suitableCameras = nil;
		self.selectedCamera = nil;
		return;
	}
	
	self.selectedCamera = self.suitableCameras.firstObject;
	
	
	// Find lenses
	NSArray<TSLFLens *> *lenses = [[TSLFDatabase sharedInstance] lensesForImage:self.activeImage withFlags:0];
	DDLogVerbose(@"Lenses: %@", lenses);
	
	// Sort lenses
	NSSortDescriptor *sortScore = [NSSortDescriptor sortDescriptorWithKey:@"sortingScore"
																ascending:NO];
	self.suitableLenses = [lenses sortedArrayUsingDescriptors:@[sortScore]];
	self.selectedLens = self.suitableLenses.lastObject;
	
	// Change tracking was disabled
	self.ignoreChanges = NO;
}

#pragma mark Settings Saving/Loading
/**
 * Copies the settings dictionary back into the image object, then saves
 * it. This also requests that the image is re-rendered.
 */
- (void) saveAfterSettingsChange {
	// Perform the request in a save block
	[TSCoreDataStore saveWithBlock:^(NSManagedObjectContext *ctx) {
		TSLibraryImage *im = [self.activeImage TSInContext:ctx];
		[self saveAdjustmentData:im];
	} completion:^(BOOL saved, NSError *err) {
		// If the context was saved, perform the "settings changed" block
		if(saved) {
			if(self.settingsChangeBlock) {
				self.settingsChangeBlock();
			}
		} else if(err != nil) {
			DDLogError(@"Error saving image: %@", err);
			
			[NSApp presentError:err modalForWindow:self.view.window
					   delegate:nil didPresentSelector:nil
					contextInfo:nil];
		}
		// If it wasn't saved, but there was no error, there were no changes to save
	}];
}

/**
 * Loads the adjustments data from the image.
 */
- (void) loadAdjustmentData {
	self.ignoreChanges = YES;
	
	// Allow change handling again
	self.ignoreChanges = NO;
}

/**
 * Saves adjustment data back into the given image.
 */
- (void) saveAdjustmentData:(TSLibraryImage *) im {
	
}

/**
 * Adds KVO observers to the mirror properties.
 */
- (void) addAdjustmentKVO {
	NSArray *keys = @[@"correctionsEnabled", @"selectedCamera", @"selectedLens"];
	
	for(NSString *key in keys) {
		[self addObserver:self forKeyPath:key
				  options:0 context:TSSettingsKVOCtx];
	}
}

/**
 * Removes any previously installed KVO listeners.
 */
- (void) removeAdjustmentKVO {
	NSArray *keys = @[@"correctionsEnabled", @"selectedCamera", @"selectedLens"];
	
	for(NSString *key in keys) {
		@try {
			[self removeObserver:self forKeyPath:key];
		} @catch (NSException * __unused) {}
	}
}


@end
