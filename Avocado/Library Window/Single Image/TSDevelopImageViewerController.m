//
//  TSDevelopImageViewerController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopImageViewerController.h"
#import "TSDevelopSidebarController.h"

#import "TSHumanModels.h"
#import "TSRawPipeline.h"

// library image changed
static void *TSImageKVO = &TSImageKVO;
// display image changed
static void *TSDisplayedImageKVO = &TSDisplayedImageKVO;

@interface TSDevelopImageViewerController ()

@property (nonatomic) IBOutlet NSScrollView *scrollView;

@property (nonatomic) NSImage *displayedImage;
@property (nonatomic) NSView *imageDisplayView;

@property (nonatomic) TSRawPipeline *pipelineRaw;

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
		[self addObserver:self forKeyPath:@"displayedImage"
				  options:0 context:TSDisplayedImageKVO];
		
		// set up rendering pipelines
		self.pipelineRaw = [TSRawPipeline new];
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
		if(self.image != nil) {
			[self processCurrentImage];
		} else {
			self.displayedImage = nil;
		}
	}
	// the display image was changed
	else if(context == TSDisplayedImageKVO) {
		// update sidebar histogram
		self.sidebar.displayedImage = self.displayedImage;
		
		// update the image view
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateImageView];
		});
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
	NSSize imageSize = self.image.rotatedImageSize;
	
	self.imageDisplayView.frame = (NSRect) {
		.size = imageSize,
		.origin = NSZeroPoint
	};
	self.imageDisplayView.layer.frame = self.imageDisplayView.frame;
	
	((NSView *) self.scrollView.documentView).frame = self.imageDisplayView.frame;
	
	// zoom out to fit the image
	CGFloat xFactor = NSWidth(self.scrollView.bounds) / imageSize.width;
	CGFloat yFactor = NSHeight(self.scrollView.bounds) / imageSize.height;
	
	self.scrollView.magnification = MIN(xFactor, yFactor);
}

/**
 * Runs the current image through the processing pipeline.
 */
- (void) processCurrentImage {
	DDAssert(self.image != nil, @"Image cannot be nil");
	
	// read out a thumbnail
	self.displayedImage = nil;
	
	// actually process the image
	if(self.image.fileTypeValue == TSLibraryImageRaw) {
		// submit the RAW image to the rendering pipeline
		[self.pipelineRaw queueRawFile:self.image shouldCache:YES completionCallback:^(NSImage *img, NSError *err) {
			if(img) {
				self.displayedImage = img;
			} else {
				DDLogError(@"Error processing image: %@", err);
			}
		} progressCallback:^(TSRawPipelineStage stage) {
			
		} conversionProgress:nil];
	}
}

#pragma mark State Restoration
/**
 * Saves view state.
 */
- (void) saveViewOptions:(NSKeyedArchiver *) archiver {
	
}

/**
 * Restores previously saved view state.
 */
- (void) restoreViewOptions:(NSKeyedUnarchiver *) unArchiver {
	
}

@end
