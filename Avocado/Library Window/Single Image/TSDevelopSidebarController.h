//
//  TSDevelopSidebarController.h
//  Avocado
//
//	This view controller is displayed on the right side of the develop view, and
//	shows Mr. Histogram, among other editing controls.
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TSDevelopImageViewerController;
@class TSLibraryImage;
@interface TSDevelopSidebarController : NSViewController

/// current library image
@property (nonatomic) TSLibraryImage *image;
/// a pointer to the image being displayed at this time
@property (nonatomic, weak) NSImage *displayedImage;

@property (nonatomic, weak) TSDevelopImageViewerController *imageViewer;

- (void) saveViewOptions:(NSKeyedArchiver *) archiver;
- (void) restoreViewOptions:(NSKeyedUnarchiver *) unArchiver;

@end
