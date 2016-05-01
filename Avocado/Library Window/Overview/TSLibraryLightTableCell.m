//
//  TSLibraryLightTableCell.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryLightTableCell.h"

#import "TSHumanModels.h"

/// height of the top information container
static const CGFloat kTopInfoBoxHeight = 60.f;

/// inset on the left/right side for the image
static const CGFloat kImageHInset = 15.f;
/// inset on the top/bottom for the image
static const CGFloat kImageVInset = 75.f;

@interface TSLibraryLightTableCell ()

@property (nonatomic) CATextLayer *sequenceNumber;
@property (nonatomic) CALayer *imageLayer;

@property (nonatomic) CAShapeLayer *darkBorder; // right, bottom
@property (nonatomic) CAShapeLayer *lightBorder; // left, top

@property (nonatomic) CALayer *topInfoContainer;
@property (nonatomic) CALayer *topInfoBorder;

- (void) setUpMainLayersWithParent:(CALayer *) layer;
- (void) setUpBordersWithParent:(CALayer *) layer;
- (void) setUpTopInfoBoxWithParent:(CALayer *) layer;

- (void) layOutContentLayers;
- (void) layOutTopInfoBox;

@end

@implementation TSLibraryLightTableCell
@dynamic representedObject;

/**
 * Initializes the light table cell, building the layers that we desire so that
 * the image and such can be displayed.
 */
- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.view.wantsLayer = YES;
	CALayer *layer = self.view.layer;
	
	// set up the main layer pls
//	layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.42 alpha:1.f].CGColor;
	layer.masksToBounds = YES;
	
	// set up main content
	[self setUpMainLayersWithParent:layer];
	
	// set up top box
	[self setUpTopInfoBoxWithParent:layer];
	
	// at the end, add the light and dark borders
	[self setUpBordersWithParent:layer];
}


/**
 * Sets up the main layers.
 */
- (void) setUpMainLayersWithParent:(CALayer *) layer {
	// create the sequence number layer
	self.sequenceNumber = [CATextLayer layer];
	self.sequenceNumber.delegate = self;
	
	self.sequenceNumber.font = (__bridge CFTypeRef _Nullable)([NSFont monospacedDigitSystemFontOfSize:48 weight:NSFontWeightBold]);
	self.sequenceNumber.fontSize = 48;
	self.sequenceNumber.foregroundColor = [NSColor colorWithCalibratedWhite:0.84 alpha:1.f].CGColor;
	
	self.sequenceNumber.alignmentMode = kCAAlignmentRight;
	
	self.sequenceNumber.string = @"1234";
	
	[layer addSublayer:self.sequenceNumber];
	
	// set up image layer
	self.imageLayer = [CALayer layer];
	self.imageLayer.delegate = self;
	
	self.imageLayer.borderWidth = 1.f;
	self.imageLayer.borderColor = [NSColor redColor].CGColor;
	
	self.imageLayer.shadowColor = [NSColor colorWithCalibratedWhite:0.1 alpha:1.f].CGColor;
	self.imageLayer.shadowRadius = 4.f;
	self.imageLayer.shadowOffset = CGSizeMake(4, 4);
	self.imageLayer.shadowOpacity = 0.2f;
	
	self.imageLayer.contentsGravity = kCAGravityResizeAspect;
	
	[layer addSublayer:self.imageLayer];
}

/**
 * Sets up the top information box's layers.
 */
- (void) setUpTopInfoBoxWithParent:(CALayer *) layer {
	// create top info layer
	self.topInfoContainer = [CALayer layer];
	self.topInfoContainer.backgroundColor = [NSColor colorWithCalibratedWhite:0.74 alpha:0.5].CGColor;
	
	self.topInfoContainer.masksToBounds = YES;
	
	[layer addSublayer:self.topInfoContainer];
	
	self.topInfoBorder = [CALayer layer];
	self.topInfoBorder.backgroundColor = [NSColor colorWithCalibratedWhite:0.40 alpha:0.5].CGColor;
	
	[self.topInfoContainer addSublayer:self.topInfoBorder];
}

/**
 * Sets up the borders around the perimeter of the cell.
 */
- (void) setUpBordersWithParent:(CALayer *) layer {
	// set up the dark border
	self.darkBorder = [CAShapeLayer layer];
	self.darkBorder.delegate = self;
	self.darkBorder.fillColor = [NSColor colorWithCalibratedWhite:0.40 alpha:1.f].CGColor;
	
	[layer addSublayer:self.darkBorder];
	
	self.lightBorder = [CAShapeLayer layer];
	self.lightBorder.delegate = self;
	self.lightBorder.fillColor = [NSColor colorWithCalibratedWhite:0.50 alpha:1.f].CGColor;
	
	[layer addSublayer:self.lightBorder];
}

#pragma mark Layouting
/**
 * Forces the cell to lay its content out again.
 */
- (void) forceRelayout {
	[self layOutContentLayers];
}

/**
 * Lays out the sublayers.
 */
- (void) viewDidLayout {
	[super viewDidLayout];
	[self layOutContentLayers];
}

/**
 * Lays out all of the containing layers.
 */
- (void) layOutContentLayers {
	NSRect frame = self.view.bounds;
	
	
	// lay out sequence number
	self.sequenceNumber.frame = CGRectMake(0, frame.size.height - 53, frame.size.width - 8, 52);
	
	
	// lay out image layer
	NSSize imageSize = self.representedObject.thumbnail.size;
	
	// calculate the size
	CGFloat originalHeight = imageSize.height;
	CGFloat originalWidth = imageSize.width;
	
	CGFloat xScale = (frame.size.width - (kImageHInset * 2.f)) / originalWidth;
	CGFloat yScale = (frame.size.height - (kImageVInset * 2.f)) / originalHeight;
	
//	CGFloat scale = (originalWidth < originalHeight) ? fminf(xScale, yScale) : fmaxf(xScale, yScale);
	CGFloat scale = fminf(xScale, yScale);
	
	CGFloat finalHeight = originalHeight * scale;
	CGFloat finalWidth = originalWidth * scale;
	
	imageSize = NSMakeSize(finalWidth, finalHeight);
	
	// center the image in the main layer, and set its frame
	CGFloat imageX = (frame.size.width - imageSize.width) / 2.f;
	CGFloat imageY = (frame.size.height - imageSize.height) / 2.f;
	
	self.imageLayer.frame = (CGRect) {
		.size = imageSize,
		.origin = CGPointMake(imageX, imageY)
	};
	self.imageLayer.frame = [self.view backingAlignedRect:self.imageLayer.frame options:NSAlignAllEdgesOutward];
	self.imageLayer.shadowPath = CGPathCreateWithRect(self.imageLayer.bounds, NULL);
	
	
	// lay out the dark border (right, bottom)
	CGMutablePathRef darkPath = CGPathCreateMutable();
	CGPathAddRect(darkPath, NULL, CGRectMake((frame.size.width - 1), 0, 1, frame.size.height));
	CGPathAddRect(darkPath, NULL, CGRectMake(0, 0, (frame.size.width - 1), 1));
	
	self.darkBorder.path = darkPath;
	self.darkBorder.frame = self.view.bounds;
	
	// lay out the light border (left, top)
	CGMutablePathRef lightPath = CGPathCreateMutable();
	CGPathAddRect(lightPath, NULL, CGRectMake(0, 1, 1, (frame.size.height - 1)));
	CGPathAddRect(lightPath, NULL, CGRectMake(0, (frame.size.height - 1), (frame.size.width - 1), 1));
	
	self.lightBorder.path = lightPath;
	self.lightBorder.frame = self.view.bounds;
	
	// update scale factor
//	[self updateContentScales];
	
	// lay out info box
	[self layOutTopInfoBox];
}

/**
 * Lays out the top info box.
 */
- (void) layOutTopInfoBox {
	NSRect frame = self.view.bounds;
	
	// set its width to 100%, height predefined, fixed to top
	self.topInfoContainer.frame = (CGRect) {
		.size = CGSizeMake(frame.size.width, kTopInfoBoxHeight),
		.origin = CGPointMake(0, frame.size.height - kTopInfoBoxHeight)
	};
	
	// add the border at the very bottom
	self.topInfoBorder.frame = CGRectMake(0, 1, frame.size.width, 1);
}

/**
 * Updates the content scales of the layers so they render properly.
 */
//- (void) updateContentScales {
//	// get the scale from the view
//	CGFloat scaleFactor = self.view.window.backingScaleFactor;
//	
//	// set it on all layers that need it
//	self.sequenceNumber.contentsScale = scaleFactor;
//	self.imageLayer.contentsScale = scaleFactor;
//}

/**
 * Allow layers to be automagically updated.
 */
- (BOOL)layer:(CALayer *) layer
shouldInheritContentsScale:(CGFloat) newScale
   fromWindow:(NSWindow *) window {
	return YES;
}

#pragma mark Properties
/**
 * Updates the cell when the represented object is updated.
 */
- (void) setRepresentedObject:(TSLibraryImage *) image {
	super.representedObject = image;
	
	self.imageLayer.contents = image.thumbnail;
}

/**
 * Sets the sequence number field.
 */
- (void) setImageSequence:(NSUInteger) seq {
	_imageSequence = seq;
	
	self.sequenceNumber.string = [NSString stringWithFormat:@"%lu", (unsigned long) seq];
}

@end
