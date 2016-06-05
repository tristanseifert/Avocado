//
//  TSDevelopImageViewerController.h
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TSDevelopSidebarController;
@class TSLibraryImage;
@interface TSDevelopImageViewerController : NSViewController

@property (nonatomic) TSLibraryImage *image;

@property (nonatomic, weak) TSDevelopSidebarController *sidebar;

- (void) saveViewOptions:(NSKeyedArchiver *) archiver;
- (void) restoreViewOptions:(NSKeyedUnarchiver *) unArchiver;

/**
 * Runs the current image through the processing pipeline.
 *
 * @param ignoreCache Set to YES to ignore any caches that may have been used
 * in the processing chain otherwise.
 */
- (void) processCurrentImageIgnoreCache:(BOOL) ignoreCache;

@end
