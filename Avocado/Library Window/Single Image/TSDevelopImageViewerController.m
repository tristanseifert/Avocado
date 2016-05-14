//
//  TSDevelopImageViewerController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopImageViewerController.h"

#import "TSHumanModels.h"

static void *TSImageKVO = &TSImageKVO;

@interface TSDevelopImageViewerController ()

@property (nonatomic) IBOutlet NSScrollView *scrollView;

@property (nonatomic) NSImage *displayedImage;
@property (nonatomic) NSView *imageDisplayView;

- (void) updateImageView;

@end

@implementation TSDevelopImageViewerController

/**
 * Initializes the view controller itself.
 */
- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopImageViewerController" bundle:nil]) {
		// add KVO for the image
		[self addObserver:self forKeyPath:@"image" options:0 context:TSImageKVO];
	}
	
	return self;
}

/**
 * Sets up the image view.
 */
- (void) viewDidLoad {
    [super viewDidLoad];
	
	// set up image view
	self.imageDisplayView = [[NSView alloc] initWithFrame:NSZeroRect];
	self.imageDisplayView.wantsLayer = YES;
	
	self.scrollView.documentView = self.imageDisplayView;
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

@end
