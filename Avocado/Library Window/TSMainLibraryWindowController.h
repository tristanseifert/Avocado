//
//  TSMainLibraryWindowController.h
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TSLibraryImage, TSHistogramView;
@interface TSMainLibraryWindowController : NSWindowController <NSWindowDelegate>

/**
 * Sets the editing/detail controller as the content view controller, then
 * loads the specified image into it.
 */
- (void) openEditorForImage:(TSLibraryImage *) image;

/**
 * Switches to the light table view.
 */
- (void) openLightTable;

@property (nonatomic) IBOutlet TSHistogramView *histo;

- (IBAction) loadHistoImage:(id) sender;

@end
