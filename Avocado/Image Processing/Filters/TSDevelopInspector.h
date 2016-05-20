//
//  TSDevelopInspector.h
//  Avocado
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TSLibraryImage;
@interface TSDevelopInspector : NSViewController

/// settings dictionary
@property (nonatomic) NSMutableDictionary<NSString *, id> *settings;

/// selected image
@property (nonatomic, weak) TSLibraryImage *activeImage;
/// output of last render pass
@property (nonatomic, weak) NSImage *renderedImage;

/**
 * This block is executed when the image adjustments have been changed.
 * It may be ran on any thread.
 */
@property (nonatomic, copy) void (^settingsChangeBlock)(void);

@end
