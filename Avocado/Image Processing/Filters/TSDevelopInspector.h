//
//  TSDevelopInspector.h
//  Avocado
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/// this evaluates to the image adjustment for the given key
#define TSAdjustment(im, key) \
((TSLibraryImageAdjustment *) [im.adjustments valueForKey:key])

/// evaluates to the X value of an adjustment
#define TSAdjustmentX(im, key) TSAdjustment(im, key).x
/// evaluates to the Y value of an adjustment
#define TSAdjustmentY(im, key) TSAdjustment(im, key).y
/// evaluates to the Z value of an adjustment
#define TSAdjustmentZ(im, key) TSAdjustment(im, key).z
/// evaluates to the W value of an adjustment
#define TSAdjustmentW(im, key) TSAdjustment(im, key).w

@class TSLibraryImage;
@interface TSDevelopInspector : NSViewController

/// selected image
@property (nonatomic, weak) TSLibraryImage *activeImage;
/// output of last render pass
@property (nonatomic, weak) NSImage *renderedImage;

/**
 * This block is executed when the image adjustments have been changed.
 * It may be ran on any thread.
 */
@property (nonatomic, copy) void (^settingsChangeBlock)(void);

/// restorable state; set to restore state, read to get a dict.
@property (nonatomic) NSDictionary *restorableState;

@end
