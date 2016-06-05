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
static void *TSCorrectionsEnabledKVOCtx = &TSCorrectionsEnabledKVOCtx;

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
		[self addObserver:self forKeyPath:@"correctionsEnabled"
				  options:0 context:TSCorrectionsEnabledKVOCtx];
		
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
	
	@try {
		[self removeObserver:self forKeyPath:@"activeImage"];
	} @catch(NSException * __unused) { }
	@try {
		[self removeObserver:self forKeyPath:@"correctionsEnabled"];
	} @catch(NSException * __unused) { }
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
		
		if(self.activeImage) {
			// Populate a list of cameras and lenses that could work
			[self findMatchingCameraLensCombinations];
			
			// Set the lenses that were saved, if existent
			[self loadAdjustmentData];
		}
	}
	// Settings changed
	else if(context == TSSettingsKVOCtx) {
		if(self.ignoreChanges == NO) {
			[self settingsChanged];
		}
	}
	// Corrections enabled state changed
	else if(context == TSCorrectionsEnabledKVOCtx) {
		if(self.ignoreChanges == NO) {
			self.isSelectionAllowed = self.correctionsEnabled;
		}
	}
	// Anything else
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
//	DDLogVerbose(@"Camera: %@", cam);
	
	if(cam != nil) {
		self.suitableCameras = @[cam];
	} else {
		self.suitableCameras = nil;
		self.selectedCamera = nil;
		return;
	}
	
	
	// Find lenses
	NSArray<TSLFLens *> *lenses = [[TSLFDatabase sharedInstance] lensesForImage:self.activeImage withFlags:0];
//	DDLogVerbose(@"Lenses: %@", lenses);
	
	// Sort lenses
	NSSortDescriptor *sortScore = [NSSortDescriptor sortDescriptorWithKey:@"sortingScore"
																ascending:NO];
	self.suitableLenses = [lenses sortedArrayUsingDescriptors:@[sortScore]];
	
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
				self.settingsChangeBlock(YES);
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
	
	// Get the corrections object
	TSLibraryImageCorrectionData *correction = self.activeImage.correctionData;
	
	self.correctionsEnabled = correction.enabled;
	self.isSelectionAllowed = correction.enabled;
	
	if(correction != nil) {
		// Unarchive the camera first
		NSData *camData = correction.cameraData;
		TSLFCamera *cam = [[TSLFDatabase sharedInstance] findCameraWithPersistentData:camData];
		
		self.selectedCamera = cam;
		
		// Unarchive the lens after that
		NSData *lensData = correction.lensData;
		TSLFLens *lens = [[TSLFDatabase sharedInstance] findLensWithPersistentData:lensData andCamera:cam];
		
		self.selectedLens = lens;
	} else {
		// Set the default lens/camera combination if no correction data is available
		self.selectedCamera = self.suitableCameras.firstObject;
		self.selectedLens = self.suitableLenses.firstObject;
	}
	
	// Allow change handling again
	self.ignoreChanges = NO;
}

/**
 * Saves adjustment data back into the given image.
 */
- (void) saveAdjustmentData:(TSLibraryImage *) im {
	// Get the corrections object
	TSLibraryImageCorrectionData *correction = im.correctionData;
	correction.enabled = self.correctionsEnabled;
	
	// If corrections are enabled, archive the camera/lens data
	if(self.correctionsEnabled.boolValue == YES) {
		correction.cameraData = self.selectedCamera.persistentData;
		correction.lensData = self.selectedLens.persistentData;
	}
	// Otherwise, set these to nil
	else {
		correction.cameraData = correction.lensData = nil;
	}
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
