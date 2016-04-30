//
//  TSLibraryDetailController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryDetailController.h"

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
//	self.displayedImage = [[NSImage alloc] initWithContentsOfFile:@"/Volumes/Datas/Photog/2016/2016-03-24/IMG_0018.CR2"];
	self.displayedImage = [[NSImage alloc] initWithContentsOfFile:@"/Volumes/Datas/Photog/2016/2016-04-27/IMG_5330.JPG"];
	
	[self updateImageView];
}

/**
 * Actually renders the image, once it has appeared.
 */
- (void) viewDidAppear {
	[super viewDidAppear];
	
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

@end
