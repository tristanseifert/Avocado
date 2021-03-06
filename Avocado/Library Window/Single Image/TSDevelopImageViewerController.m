//
//  TSDevelopImageViewerController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopImageViewerController.h"
#import "TSDevelopSidebarController.h"
#import "TSDevelopLoadingIndicatorWindowController.h"
#import "TSThumbCache.h"

#import "TSBufferOwningBitmapRep.h"
#import "TSHumanModels.h"
#import "TSRawPipeline.h"

// Library image changed
static void *TSImageKVO = &TSImageKVO;
// Display image changed
static void *TSDisplayedImageKVO = &TSDisplayedImageKVO;

@interface TSDevelopImageViewerController ()

@property (nonatomic) IBOutlet NSScrollView *scrollView;

@property (nonatomic) NSImage *displayedImage;
@property (nonatomic) NSView *imageDisplayView;

@property (nonatomic) TSRawPipeline *pipelineRaw;

@property (nonatomic) BOOL shouldAdjustImageSize;

/// When set, the full-res image has already been displayed, so ignore the thumb.
@property (nonatomic) BOOL hasShownFullResImage;

// Loading controller
@property (nonatomic) TSDevelopLoadingIndicatorWindowController *loadController;

- (void) updateImageView;

@end

@implementation TSDevelopImageViewerController

/**
 * Initializes the view controller itself.
 */
- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopImageViewerController" bundle:nil]) {
		// Add KVO for the image
		[self addObserver:self forKeyPath:@"image" options:0 context:TSImageKVO];
		[self addObserver:self forKeyPath:@"displayedImage"
				  options:0 context:TSDisplayedImageKVO];
		
		// Set up rendering pipelines
		self.pipelineRaw = [TSRawPipeline new];
		
		// Set up load controller
		self.loadController = [TSDevelopLoadingIndicatorWindowController new];
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
	self.imageDisplayView.layer.drawsAsynchronously = YES;
	
	self.scrollView.documentView = self.imageDisplayView;
}

/**
 * When the view appears, add the loading window as a subwindow.
 */
- (void) viewWillAppear {
	[super viewWillAppear];
	
	[self.view.window addChildWindow:self.loadController.window
							 ordered:NSWindowAbove];
}

/**
 * When the view disappeared, hide the loading window.
 */
- (void) viewDidDisappear {
	[super viewDidDisappear];
	
	[self.view.window removeChildWindow:self.loadController.window];
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
		// clear the image for now
		self.displayedImage = nil;
		
		// if there is a new image, process it
		if(self.image != nil) {
			// Cause the view to be resized
			self.hasShownFullResImage = NO;
			self.shouldAdjustImageSize = YES;
			
			// Get a thumbnail
			CGFloat s = MAX(NSWidth(self.view.bounds), NSHeight(self.view.bounds));
			
			[[TSThumbCache sharedInstance] getThumbForImage:self.image withSize:NSMakeSize(s, s) andCallback:^(NSImage *thumb, __unused void *userData) {
				if(self.hasShownFullResImage == NO) {
					self.displayedImage = thumb;
				}
			} withUserData:nil];
	
			// Process image
			[self processCurrentImageIgnoreCache:NO];
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
	if(self.shouldAdjustImageSize == YES) {
		CGFloat xFactor = NSWidth(self.scrollView.bounds) / imageSize.width;
		CGFloat yFactor = NSHeight(self.scrollView.bounds) / imageSize.height;
	
		self.scrollView.magnification = MIN(xFactor, yFactor);
	}
}

/**
 * Runs the current image through the processing pipeline.
 */
- (void) processCurrentImageIgnoreCache:(BOOL) ignoreCache {
	DDAssert(self.image != nil, @"Image cannot be nil");
	
	// Show loading indicator
	[self.loadController showLoadingWindowInView:self.view withAnimation:YES];
	
	// Deallocate previous image
	if(self.displayedImage != nil) {
		// Get representations in this buffer, and free whatever ones can be freed
		[self.displayedImage.representations enumerateObjectsUsingBlock:^(NSImageRep *rep, NSUInteger idx, BOOL *stop) {
			if([rep isKindOfClass:[TSBufferOwningBitmapRep class]]) {
				DDLogDebug(@"Found %@ in image %@", rep, self.displayedImage);
				
				// Free the buffers
				TSBufferOwningBitmapRep *bm = (TSBufferOwningBitmapRep *) rep;
				[bm TSFreeBuffers];
			}
		}];
	}
	
	// Actually process the image
	if(self.image.fileTypeValue == TSLibraryImageRaw) {
		// Submit the RAW image to the rendering pipeline
		[self.pipelineRaw queueRawFile:self.image shouldCache:YES inhibitCachedResume:ignoreCache renderingIntent:TSRawPipelineIntentDisplayFast outputFormat:TSRawPipelineOutputFormatNSImage completionCallback:^(NSImage *img, NSError *err) {
			// Display it
			if(img) {
				self.hasShownFullResImage = YES;
				self.displayedImage = img;
			} else {
				DDLogError(@"Error processing image: %@", err);
			}
			
			// Hide and disallow further view resizing
			self.shouldAdjustImageSize = NO;
			
			[self.loadController hideLoadingWindowWithAnimation:YES];
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
