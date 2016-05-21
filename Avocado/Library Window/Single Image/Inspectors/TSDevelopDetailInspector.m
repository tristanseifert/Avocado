//
//  TSDevelopDetailInspector.m
//  Avocado
//
//  Created by Tristan Seifert on 20160518.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopDetailInspector.h"

#import "TSHumanModels.h"

#import <MagicalRecord/MagicalRecord.h>

static void *TSActiveImageKVOCtx = &TSActiveImageKVOCtx;
static void *TSSettingsKVOCtx = &TSSettingsKVOCtx;

/// delay between invocations of change that must pass to re-render image
static const NSTimeInterval TSSettingsChangeDebounce = 0.66f;


@interface TSDevelopDetailInspector ()

/// when set, any changes to the image properties are ignored
@property (nonatomic) BOOL ignoreChanges;

- (void) loadAdjustmentData;
- (void) saveAdjustmentData:(TSLibraryImage *) im;

- (void) addAdjustmentKVO;
- (void) removeAdjustmentKVO;

- (void) settingsChanged;
- (void) saveAfterSettingsChange;

@end

@implementation TSDevelopDetailInspector

- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopDetailInspector" bundle:nil]) {
		self.title = NSLocalizedString(@"Detail", @"detail inspector title");
		self.preferredContentSize = NSMakeSize(0, 223);
		
		// add some KVO observers
		[self addObserver:self forKeyPath:@"activeImage"
				  options:0 context:TSActiveImageKVOCtx];
		
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
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *ctx) {
		TSLibraryImage *im = [self.activeImage MR_inContext:ctx];
		[self saveAdjustmentData:im];
	} completion:^(BOOL saved, NSError *err) {
		// if the context was saved, perform the "settings changed" block
		if(saved) {
			if(self.settingsChangeBlock) {
				self.settingsChangeBlock();
			}
		} else {
			DDLogError(@"Error saving image: %@", err);
			
			[NSApp presentError:err modalForWindow:self.view.window
					   delegate:nil didPresentSelector:nil
					contextInfo:nil];
		}
	}];
}

/**
 * Loads the adjustments data from the image.
 */
- (void) loadAdjustmentData {
	self.ignoreChanges = YES;
	
	// load noise reduction level
	self.nrLevel = TSAdjustmentXDbl(self.activeImage, TSAdjustmentKeyNoiseReductionLevel);
	// load noise reduction sharpness
	self.nrSharpness = TSAdjustmentXDbl(self.activeImage, TSAdjustmentKeyNoiseReductionSharpness);
	
	// load sharpening — luminance
	self.sharpenLuminance = TSAdjustmentXDbl(self.activeImage, TSAdjustmentKeySharpenLuminance);
	// load sharpening — radius
	self.sharpenRadius = TSAdjustmentXDbl(self.activeImage, TSAdjustmentKeySharpenRadius);
	// load sharpening — intensity
	self.sharpenIntensity = TSAdjustmentXDbl(self.activeImage, TSAdjustmentKeySharpenIntensity);
	
	// load median filter
	self.sharpenMedianFilter = TSAdjustment(self.activeImage, TSAdjustmentKeySharpenMedianFilter).x.boolValue;
	
	// allow change handling again
	self.ignoreChanges = YES;
}

/**
 * Saves adjustment data back into the given image.
 */
- (void) saveAdjustmentData:(TSLibraryImage *) im {
	// save noise reduction level
	TSAdjustment(im, TSAdjustmentKeyNoiseReductionLevel).x = @(self.nrLevel);
	
	// save noise reduction sharpness
	TSAdjustment(im, TSAdjustmentKeyNoiseReductionSharpness).x = @(self.nrSharpness);
	
	
	// save sharpening — luminance
	TSAdjustment(im, TSAdjustmentKeySharpenLuminance).x = @(self.sharpenLuminance);
	// save sharpening — radius
	TSAdjustment(im, TSAdjustmentKeySharpenRadius).x = @(self.sharpenRadius);
	// save sharpening — intensity
	TSAdjustment(im, TSAdjustmentKeySharpenIntensity).x = @(self.sharpenIntensity);
	
	// save median filter
	TSAdjustment(im, TSAdjustmentKeySharpenMedianFilter).x = @(self.sharpenMedianFilter);
}

/**
 * Adds KVO observers to the mirror properties.
 */
- (void) addAdjustmentKVO {
	NSArray *keys = @[@"nrLevel", @"nrSharpness", @"sharpenLuminance", @"sharpenRadius", @"sharpenIntensity", @"sharpenMedianFilter"];
	
	for(NSString *key in keys) {
		[self addObserver:self forKeyPath:key
				  options:0 context:TSSettingsKVOCtx];
	}
}

/**
 * Removes any previously installed KVO listeners.
 */
- (void) removeAdjustmentKVO {
	NSArray *keys = @[@"nrLevel", @"nrSharpness", @"sharpenLuminance", @"sharpenRadius", @"sharpenIntensity", @"sharpenMedianFilter"];
	
	for(NSString *key in keys) {
		@try {
			[self removeObserver:self forKeyPath:key];
		} @catch (NSException * __unused) {}
	}
}

@end
