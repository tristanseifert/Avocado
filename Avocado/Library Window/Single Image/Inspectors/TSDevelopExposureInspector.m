//
//  TSDevelopExposureInspector.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopExposureInspector.h"

#import "TSHumanModels.h"
#import "TSCoreDataStore.h"

static void *TSActiveImageKVOCtx = &TSActiveImageKVOCtx;
static void *TSSettingsKVOCtx = &TSSettingsKVOCtx;

/// delay between invocations of change that must pass to re-render image
static const NSTimeInterval TSSettingsChangeDebounce = 0.66f;

@interface TSDevelopExposureInspector ()

/// when set, any changes to the image properties are ignored
@property (nonatomic) BOOL ignoreChanges;

- (void) loadAdjustmentData;
- (void) saveAdjustmentData:(TSLibraryImage *) im;

- (void) addAdjustmentKVO;
- (void) removeAdjustmentKVO;

- (void) settingsChanged;
- (void) saveAfterSettingsChange;

@end

@implementation TSDevelopExposureInspector

- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopExposureInspector" bundle:nil]) {
		self.title = NSLocalizedString(@"Exposure", @"exposure inspector title");
		self.preferredContentSize = NSMakeSize(0, 238);
		
		// add some KVO observers
		[self addObserver:self forKeyPath:@"activeImage"
				  options:0 context:TSActiveImageKVOCtx];
		
		self.ignoreChanges = YES;
		[self addAdjustmentKVO];
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
	// image changed
	if(context == TSActiveImageKVOCtx) {
		// cancel last invocation for settings change
		[[self class] cancelPreviousPerformRequestsWithTarget:self
													 selector:@selector(saveAfterSettingsChange)
													   object:nil];
		
		// copy the image adjustments
		if(self.activeImage) {
			[self loadAdjustmentData];
		}
	}
	// settings changed
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
	// cancel previous invocations
	[[self class] cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(saveAfterSettingsChange)
												   object:nil];
	
	// invoke after delay
	[self performSelector:@selector(saveAfterSettingsChange)
			   withObject:nil afterDelay:TSSettingsChangeDebounce];
}

#pragma mark Settings Saving/Loading
/**
 * Copies the settings dictionary back into the image object, then saves
 * it. This also requests that the image is re-rendered.
 */
- (void) saveAfterSettingsChange {
	// perform the request in a save block
	[TSCoreDataStore saveWithBlock:^(NSManagedObjectContext *ctx) {
		TSLibraryImage *im = [self.activeImage TSInContext:ctx];
		[self saveAdjustmentData:im];
	} completion:^(BOOL saved, NSError *err) {
		// if the context was saved, perform the "settings changed" block
		if(saved) {
			if(self.settingsChangeBlock) {
				self.settingsChangeBlock(NO);
			}
		} else if(err != nil) {
			DDLogError(@"Error saving image: %@", err);
			
			[NSApp presentError:err modalForWindow:self.view.window
					   delegate:nil didPresentSelector:nil
					contextInfo:nil];
		}
		// if it wasn't saved, but there was no error, there were no changes to save
	}];
}

/**
 * Loads the adjustments data from the image.
 */
- (void) loadAdjustmentData {
	self.ignoreChanges = YES;
	
	// load exposure
	self.exposureAdjustment = TSAdjustmentX(self.activeImage, TSAdjustmentKeyExposureEV);
	
	// load exposure
	self.highlightsAdjustment = TSAdjustmentX(self.activeImage, TSAdjustmentKeyExposureHighlights);
	// load exposure
	self.shadowsAdjustment = TSAdjustmentX(self.activeImage, TSAdjustmentKeyExposureShadows);
	// load exposure
	self.whitesAdjustment = TSAdjustmentX(self.activeImage, TSAdjustmentKeyExposureWhites);
	// load exposure
	self.blacksAdjustment = TSAdjustmentX(self.activeImage, TSAdjustmentKeyExposureBlacks);
	
	// load contrast
	self.contrastAdjustment = TSAdjustmentX(self.activeImage, TSAdjustmentKeyToneContrast);
	// load saturation
	self.saturationAdjustment = TSAdjustmentX(self.activeImage, TSAdjustmentKeyToneSaturation);
	// load vibrance
	self.vibranceAdjustment = TSAdjustmentX(self.activeImage, TSAdjustmentKeyToneVibrance);
	
	// allow change handling again
	self.ignoreChanges = NO;
}

/**
 * Saves adjustment data back into the given image.
 */
- (void) saveAdjustmentData:(TSLibraryImage *) im {
	// save exposure
	TSAdjustmentX(im, TSAdjustmentKeyExposureEV) = self.exposureAdjustment;
	
	// save exposure
	TSAdjustmentX(im, TSAdjustmentKeyExposureHighlights) = self.highlightsAdjustment;
	// save exposure
	TSAdjustmentX(im, TSAdjustmentKeyExposureShadows) = self.shadowsAdjustment;
	// save exposure
	TSAdjustmentX(im, TSAdjustmentKeyExposureWhites) = self.whitesAdjustment;
	// save exposure
	TSAdjustmentX(im, TSAdjustmentKeyExposureBlacks) = self.blacksAdjustment;
	
	// save contrast
	TSAdjustmentX(im, TSAdjustmentKeyToneContrast) = self.contrastAdjustment;
	// save saturation
	TSAdjustmentX(im, TSAdjustmentKeyToneSaturation) = self.saturationAdjustment;
	// save vibrancy
	TSAdjustmentX(im, TSAdjustmentKeyToneVibrance) = self.vibranceAdjustment;
}

/**
 * Adds KVO observers to the mirror properties.
 */
- (void) addAdjustmentKVO {
	NSArray *keys = @[@"exposureAdjustment", @"contrastAdjustment", @"highlightsAdjustment", @"shadowsAdjustment", @"whitesAdjustment", @"blacksAdjustment", @"saturationAdjustment", @"vibranceAdjustment"];
	
	for(NSString *key in keys) {
		[self addObserver:self forKeyPath:key
				  options:0 context:TSSettingsKVOCtx];
	}
}

/**
 * Removes any previously installed KVO listeners.
 */
- (void) removeAdjustmentKVO {
	NSArray *keys = @[@"exposureAdjustment", @"contrastAdjustment", @"highlightsAdjustment", @"shadowsAdjustment", @"whitesAdjustment", @"blacksAdjustment", @"saturationAdjustment", @"vibranceAdjustment"];
	
	for(NSString *key in keys) {
		@try {
			[self removeObserver:self forKeyPath:key];
		} @catch (NSException * __unused) {}
	}
}

@end
