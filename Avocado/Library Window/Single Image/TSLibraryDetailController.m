//
//  TSLibraryDetailController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryDetailController.h"

#import "TSHumanModels.h"
#import "TSMainLibraryWindowController.h"

static void *TSImageKVO = &TSImageKVO;

@interface TSLibraryDetailController ()

@property (nonatomic) NSImage *displayedImage;

@property (nonatomic) NSView *imageDisplayView;

- (void) updateImageView;

@end

@implementation TSLibraryDetailController

- (void) viewDidLoad {
    [super viewDidLoad];
	
	// set up image view
	self.imageDisplayView = [[NSView alloc] initWithFrame:NSZeroRect];
	self.imageDisplayView.wantsLayer = YES;
	
	self.scrollView.documentView = self.imageDisplayView;
	
	// uuuh… fugu?
//	self.displayedImage = [[NSImage alloc] initWithContentsOfFile:@"/Volumes/Datas/Photog/2016/2016-04-27/IMG_5330.JPG"];
//	[self updateImageView];
	
	// add KVO for the image
	[self addObserver:self forKeyPath:@"image" options:0 context:TSImageKVO];
}

/**
 * Tells our containing window to hide the title bar and make the content view
 * span the entire size of the window.
 */
- (void) prepareWindowForAppearance:(NSWindow *) window {
	[super prepareWindowForAppearance:window];
	
	// set up the custom window appearance
	window.toolbar.visible = YES;
	window.titlebarAppearsTransparent = YES;
	window.movableByWindowBackground = YES;
	
	window.titleVisibility = NSWindowTitleHidden;
	
	NSUInteger styleMask = window.styleMask;
	window.styleMask = styleMask | NSFullSizeContentViewWindowMask;
}

#pragma mark KVO
/**
 * Handles KVO, including that for the image changing.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath
					   ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	// the image property changed
	if(context == TSImageKVO) {
		DDLogVerbose(@"Changed image: %@", self.image.fileUrl);
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Image Handling
/**
 * Handles the image.
 */
- (void) updateImageView {
	// set image, pls.
	self.imageDisplayView.layer.contents = self.displayedImage;
	
	// update size of the image view and content view of the scroll view
	NSSize imageSize = self.displayedImage.size;
	
	self.imageDisplayView.frame = (NSRect) {
		.size = imageSize,
		.origin = NSZeroPoint
	};
	self.imageDisplayView.layer.frame = self.imageDisplayView.frame;

	((NSView *) self.scrollView.documentView).frame = self.imageDisplayView.frame;
	
	// zoom out to fit the image
}

#pragma mark UI Actions
/**
 * Returns to the light table.
 */
- (IBAction) returnToLightTable:(id) sender {
	[self.windowController openLightTable];
}

@end
