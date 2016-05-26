//
//  TSDevelopHueInspector.m
//  Avocado
//
//  Created by Tristan Seifert on 20160518.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopHueInspector.h"

#import "TSHumanModels.h"

#import <MagicalRecord/MagicalRecord.h>

static void *TSActiveImageKVOCtx = &TSActiveImageKVOCtx;
static void *TSSettingsKVOCtx = &TSSettingsKVOCtx;

/// delay between invocations of change that must pass to re-render image
static const NSTimeInterval TSSettingsChangeDebounce = 0.66f;

@interface TSDevelopHueInspector ()

/// when set, any changes to the image properties are ignored
@property (nonatomic) BOOL ignoreChanges;

- (void) loadAdjustmentData;
- (void) saveAdjustmentData:(TSLibraryImage *) im;

- (void) addAdjustmentKVO;
- (void) removeAdjustmentKVO;

- (void) settingsChanged;
- (void) saveAfterSettingsChange;

@end

@implementation TSDevelopHueInspector

- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopHueInspector" bundle:nil]) {
		self.title = NSLocalizedString(@"Hue, Saturation, Lightness", @"HSL inspector title");
		self.preferredContentSize = NSMakeSize(0, 235);
		
		// add some KVO observers
		[self addObserver:self forKeyPath:@"activeImage"
				  options:0 context:TSActiveImageKVOCtx];
		
		self.ignoreChanges = YES;
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
	
	// remove any pre-existing KVO
	[self removeAdjustmentKVO];
	
	// load all eight adjustments
	self.redAdjustments = [TSAdjustment(self.activeImage, TSAdjustmentKeyColourRed).dictRepresentation mutableCopy];
	self.orangeAdjustments = [TSAdjustment(self.activeImage, TSAdjustmentKeyColourOrange).dictRepresentation mutableCopy];
	self.yellowAdjustments = [TSAdjustment(self.activeImage, TSAdjustmentKeyColourYellow).dictRepresentation mutableCopy];
	self.greenAdjustments = [TSAdjustment(self.activeImage, TSAdjustmentKeyColourGreen).dictRepresentation mutableCopy];
	self.aquaAdjustments = [TSAdjustment(self.activeImage, TSAdjustmentKeyColourAqua).dictRepresentation mutableCopy];
	self.blueAdjustments = [TSAdjustment(self.activeImage, TSAdjustmentKeyColourBlue).dictRepresentation mutableCopy];
	self.purpleAdjustments = [TSAdjustment(self.activeImage, TSAdjustmentKeyColourPurple).dictRepresentation mutableCopy];
	self.magentaAdjustments = [TSAdjustment(self.activeImage, TSAdjustmentKeyColourMagenta).dictRepresentation mutableCopy];
	
	// Add KVO to the dictionaries
	[self addAdjustmentKVO];
	
	// allow change handling again
	self.ignoreChanges = NO;
}

/**
 * Saves adjustment data back into the given image.
 */
- (void) saveAdjustmentData:(TSLibraryImage *) im {
	// restore adjustments for all eight channels
	[TSAdjustment(im, TSAdjustmentKeyColourRed) setValuesFromDictRepresentation:[self.redAdjustments copy]];
	[TSAdjustment(im, TSAdjustmentKeyColourOrange) setValuesFromDictRepresentation:[self.orangeAdjustments copy]];
	[TSAdjustment(im, TSAdjustmentKeyColourYellow) setValuesFromDictRepresentation:[self.yellowAdjustments copy]];
	[TSAdjustment(im, TSAdjustmentKeyColourGreen) setValuesFromDictRepresentation:[self.greenAdjustments copy]];
	[TSAdjustment(im, TSAdjustmentKeyColourAqua) setValuesFromDictRepresentation:[self.aquaAdjustments copy]];
	[TSAdjustment(im, TSAdjustmentKeyColourBlue) setValuesFromDictRepresentation:[self.blueAdjustments copy]];
	[TSAdjustment(im, TSAdjustmentKeyColourPurple) setValuesFromDictRepresentation:[self.purpleAdjustments copy]];
	[TSAdjustment(im, TSAdjustmentKeyColourMagenta) setValuesFromDictRepresentation:[self.magentaAdjustments copy]];
}

/**
 * Adds KVO observers to the mirror properties.
 */
- (void) addAdjustmentKVO {
	NSArray *keys = @[@"redAdjustments", @"orangeAdjustments", @"yellowAdjustments",
					  @"greenAdjustments", @"aquaAdjustments", @"blueAdjustments",
					  @"purpleAdjustments", @"magentaAdjustments"];
	
	for(NSString *key in keys) {
		[[self valueForKey:key] addObserver:self forKeyPath:@"x"
									options:0 context:TSSettingsKVOCtx];
		[[self valueForKey:key] addObserver:self forKeyPath:@"y"
									options:0 context:TSSettingsKVOCtx];
		[[self valueForKey:key] addObserver:self forKeyPath:@"z"
									options:0 context:TSSettingsKVOCtx];
	}
}

/**
 * Removes any previously installed KVO listeners.
 */
- (void) removeAdjustmentKVO {
	NSArray *keys = @[@"redAdjustments", @"orangeAdjustments", @"yellowAdjustments",
					  @"greenAdjustments", @"aquaAdjustments", @"blueAdjustments",
					  @"purpleAdjustments", @"magentaAdjustments"];
	
	for(NSString *key in keys) {
		@try {
			[[self valueForKey:key] removeObserver:self forKeyPath:@"x"];
		} @catch (NSException * __unused) {}
		@try {
			[[self valueForKey:key] removeObserver:self forKeyPath:@"y"];
		} @catch (NSException * __unused) {}
		@try {
			[[self valueForKey:key] removeObserver:self forKeyPath:@"z"];
		} @catch (NSException * __unused) {}
	}
}


@end
