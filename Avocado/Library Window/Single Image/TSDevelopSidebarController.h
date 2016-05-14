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

@property (nonatomic) TSLibraryImage *image;

@property (nonatomic, weak) TSDevelopImageViewerController *imageViewer;

@end
