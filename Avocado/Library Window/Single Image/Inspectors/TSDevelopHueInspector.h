//
//  TSDevelopHueInspector.h
//  Avocado
//
//  Created by Tristan Seifert on 20160518.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TSLibraryImage;
@interface TSDevelopHueInspector : NSViewController

/// settings dictionary
@property (nonatomic) NSMutableDictionary<NSString *, id> *settings;

/// selected image
@property (nonatomic, weak) TSLibraryImage *activeImage;
/// output of last render pass
@property (nonatomic, weak) NSImage *renderedImage;

@end
