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
static NSTimeInterval TSSettingsChangeDebounce = 0.66f;

@interface TSDevelopDetailInspector ()

- (void) addSettingsKVO;
- (void) removeSettingsKVO;

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
	}
	
	return self;
}

/**
 * Observes KVO.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	// image changed
	if(context == TSActiveImageKVOCtx) {
		// remove settings KVO
		[self removeSettingsKVO];
		
		// cancel last invocation for settings change
		[[self class] cancelPreviousPerformRequestsWithTarget:self
													 selector:@selector(saveAfterSettingsChange)
													   object:nil];
		
		// set image
		if(self.activeImage) {
			self.settings = [self.activeImage.adjustments[TSAdjustmentKeyDetail] mutableCopy];
			[self addSettingsKVO];
		} else {
			// clear settings if no image present
			self.settings = nil;
		}
	}
	// settings changed
	else if(context == TSSettingsKVOCtx) {
		[self settingsChanged];
	}
	// anything else
	else {
		[super observeValueForKeyPath:keyPath ofObject:object
							   change:change context:context];
	}
}

/**
 * Adds KVO to the various settings dictionary keys.
 */
- (void) addSettingsKVO {
	NSArray<NSString *> *keys = @[
		TSAdjustmentKeyNoiseReductionLevel,
		TSAdjustmentKeyNoiseReductionSharpness,
		TSAdjustmentKeySharpenLuminance,
		TSAdjustmentKeySharpenRadius,
		TSAdjustmentKeySharpenIntensity,
		TSAdjustmentKeySharpenMedianFilter
	];
	
	[keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
		[self.settings addObserver:self
						forKeyPath:key
						   options:0 context:TSSettingsKVOCtx];
	}];
}

/**
 * Removes all existing KVO observers (that we registered, anyhow) from
 * the settings dictionary.
 */
- (void) removeSettingsKVO {
	NSArray<NSString *> *keys = @[
		TSAdjustmentKeyNoiseReductionLevel,
		TSAdjustmentKeyNoiseReductionSharpness,
		TSAdjustmentKeySharpenLuminance,
		TSAdjustmentKeySharpenRadius,
		TSAdjustmentKeySharpenIntensity,
		TSAdjustmentKeySharpenMedianFilter
	];
	
	[keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
		@try {
			[self.settings removeObserver:self forKeyPath:key];
		} @catch (NSException __unused *exception) { }
	}];
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

/**
 * Copies the settings dictionary back into the image object, then saves
 * it. This also requests that the image is re-rendered.
 */
- (void) saveAfterSettingsChange {
	// perform the request in a save block
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *ctx) {
		TSLibraryImage *im = [self.activeImage MR_inContext:ctx];
		
		// copy and update the adjustments dictionary
		NSMutableDictionary *adjustments = [im.adjustments mutableCopy];
		adjustments[TSAdjustmentKeyDetail] = [self.settings copy];
		
		// set it back
		im.adjustments = [adjustments copy];
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

@end
