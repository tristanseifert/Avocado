//
//  TSLibraryLightTableCell.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryLightTableCell.h"

#import "TSHumanModels.h"

// inset on the left/right side for the image
static const CGFloat kImageHInset = 20.f;
// inset on the top/bottom for the image
static const CGFloat kImageVInset = 30.f;

@interface TSLibraryLightTableCell ()

@property (nonatomic) CATextLayer *sequenceNumber;
@property (nonatomic) CALayer *imageLayer;

@property (nonatomic) CAShapeLayer *darkBorder; // right, bottom
@property (nonatomic) CAShapeLayer *lightBorder; // left, top

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
	layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.42 alpha:1.f].CGColor;
	
	layer.masksToBounds = YES;
	
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
	
	// set up the dark border
	self.darkBorder = [CAShapeLayer layer];
	self.darkBorder.delegate = self;
//	self.darkBorder.fillColor = [NSColor colorWithCalibratedWhite:0.1 alpha:1.f].CGColor;
	self.darkBorder.fillColor = [NSColor redColor].CGColor;
	
	[layer addSublayer:self.darkBorder];
	
	self.lightBorder = [CAShapeLayer layer];
	self.lightBorder.delegate = self;
//	self.darkBorder.fillColor = [NSColor colorWithCalibratedWhite:0.1 alpha:1.f].CGColor;
	self.lightBorder.fillColor = [NSColor yellowColor].CGColor;
	
	[layer addSublayer:self.lightBorder];
}

/**
 * Lays out the sublayers.
 */
- (void) viewDidLayout {
	[super viewDidLayout];
	
	NSRect frame = self.view.bounds;
	
	
	// lay out text
	self.sequenceNumber.frame = CGRectMake(0, frame.size.height - 52, frame.size.width - 4, 52);
	
	
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
	DDLogVerbose(@"Image frame: %@", NSStringFromRect(self.imageLayer.frame));
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
