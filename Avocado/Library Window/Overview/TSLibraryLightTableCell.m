//
//  TSLibraryLightTableCell.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryLightTableCell.h"
#import "TSLibraryOverviewLightTableController.h"

#import "TSThumbCache.h"
#import "TSHumanModels.h"

static void *TSLightTableCellSelectedCtx = &TSLightTableCellSelectedCtx;

NSString* const TSLibraryLightTableInvalidateThumbsNotificationName = @"TSLibraryLightTableInvalidateThumbsNotification";

/// shared date formatter for shot date
static NSDateFormatter *shotDateFormatter = nil;

/// background colour of a selected cell
#define kSelectedBackgroundColour [NSColor colorWithCalibratedWhite:0.833 alpha:1.f]
/// background colour of a cell that is being hovered over
#define kHoverBackgroundColour [NSColor colorWithCalibratedWhite:0.9 alpha:1.f]

/// colour for sequence number, for an unselected cell
#define kSequenceNumberColourUnselected [NSColor colorWithCalibratedWhite:0.875 alpha:0.64]
/// colour for sequence number, for a selected cell
#define kSequenceNumberColourSelected [NSColor colorWithCalibratedWhite:0.45 alpha:0.64]

/// height of the top information container
static const CGFloat kTopInfoBoxHeight = 65.f;
/// horizontal inset (margin) for info box content
static const CGFloat kInfoBoxHInset = 8.f;
/// vertical inset (margin) for info box content
static const CGFloat kInfoBoxVInset = 6.f;

/// primary info box text colour
#define kInfoBoxPrimaryTextColour [NSColor colorWithCalibratedWhite:0.24 alpha:1.f]
/// secondary info box text colour
#define kInfoBoxSecondaryTextColour [NSColor colorWithCalibratedWhite:0.32 alpha:1.f]

/// colour for the photo frame
#define kPhotoFrameColour [NSColor colorWithCalibratedWhite:0.20 alpha:1.f]

/// inset on the left/right side for the image
static const CGFloat kImageHInset = 15.f;
/// inset on the top/bottom for the image
static const CGFloat kImageVInset = 70.f;

/// vertical inset for thumbnails, not included in centering
static const CGFloat kThumbVMargin = 10.f;
/// horizontal inset for thumbnails, not included in centering
static const CGFloat kThumbHMargin = 5.f;

@interface TSLibraryLightTableCell ()

@property (nonatomic) CATextLayer *sequenceNumber;
@property (nonatomic) CALayer *imageLayer;
@property (nonatomic) CALayer *imageShadowLayer;

@property (nonatomic) CAShapeLayer *darkBorder; // right, bottom
@property (nonatomic) CAShapeLayer *lightBorder; // left, top

@property (nonatomic) CALayer *topInfoContainer;
@property (nonatomic) CALayer *topInfoBorder;
@property (nonatomic) CATextLayer *topInfoFileName;
@property (nonatomic) CATextLayer *topInfoSubtitle;

@property (nonatomic) CALayer *bottomInfoContainer;
@property (nonatomic) CALayer *bottomInfoBorder;

@property (nonatomic) NSTrackingArea *trackingArea;

- (void) setUpMainLayersWithParent:(CALayer *) layer;
- (void) setUpBordersWithParent:(CALayer *) layer;
- (void) setUpTopInfoBoxWithParent:(CALayer *) layer;

- (void) layOutContentLayers;
- (void) layOutTopInfoBox;

- (void) thumbsInvalidatedNotification:(NSNotification *) n;
- (void) updateThumbnails;

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
	
	// set up the shot date formatter and thumb cache
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shotDateFormatter = [NSDateFormatter new];
		
		shotDateFormatter.dateStyle = NSDateFormatterMediumStyle;
		shotDateFormatter.timeStyle = NSDateFormatterLongStyle;
		
		shotDateFormatter.locale = [NSLocale autoupdatingCurrentLocale];
		shotDateFormatter.calendar = [NSCalendar autoupdatingCurrentCalendar];
	});
	
	// Add notification handler
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(thumbsInvalidatedNotification:)
			   name:TSLibraryLightTableInvalidateThumbsNotificationName
			 object:nil];
	
	// Add KVO handler for selection
	[self addObserver:self forKeyPath:@"selected" options:0
			  context:TSLightTableCellSelectedCtx];
	
	// set up the tracking area
	self.trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect owner:self userInfo:nil];
	[self.view addTrackingArea:self.trackingArea];
}

/**
 * Clean up some resources when this cell is deallocated.
 */
- (void) dealloc {
	// remove as a notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 * Requests thumbnails to be created when the view is about to show up.
 */
- (void) viewWillAppear {
	[super viewWillAppear];
}

#pragma mark Mouse Tracking
/**
 * Mouse entered the tracking area; apply hover style.
 */
- (void) mouseEntered:(NSEvent *)theEvent {
	self.view.layer.backgroundColor = kHoverBackgroundColour.CGColor;
	self.sequenceNumber.foregroundColor = kSequenceNumberColourSelected.CGColor;
}

/**
 * Mouse left: apply the regular or highlighted styles.
 */
- (void) mouseExited:(NSEvent *)theEvent {
	if(self.selected) {
		self.view.layer.backgroundColor = kSelectedBackgroundColour.CGColor;
		self.sequenceNumber.foregroundColor = kSequenceNumberColourSelected.CGColor;
	} else {
		self.view.layer.backgroundColor = nil;
		self.sequenceNumber.foregroundColor = kSequenceNumberColourUnselected.CGColor;
	}
}

/**
 * Mouse was clicked; on double-click event, send a message to enter the editing
 * view.
 */
- (void) mouseDown:(NSEvent *) theEvent {
	[super mouseDown:theEvent];
	
	// only perform double click action if an object is associated with the cell
	if(theEvent.clickCount == 2 && self.representedObject != nil) {
		[self.controller cellWasDoubleClicked:self];
	}
}

#pragma mark KVO
/**
 * KVO Handler
 */
- (void) observeValueForKeyPath:(NSString *) keyPath
					   ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	// the selection state changed pls
	if(context == TSLightTableCellSelectedCtx) {
		if(self.selected) {
			self.view.layer.backgroundColor = kSelectedBackgroundColour.CGColor;
			self.sequenceNumber.foregroundColor = kSequenceNumberColourSelected.CGColor;
		} else {
			self.view.layer.backgroundColor = nil;
			self.sequenceNumber.foregroundColor = kSequenceNumberColourUnselected.CGColor;
		}
		
//		DDLogVerbose(@"Selected: %i", self.isSelected);
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Layer Setup
/**
 * Sets up the main layers.
 */
- (void) setUpMainLayersWithParent:(CALayer *) layer {
	// create the sequence number layer
	self.sequenceNumber = [CATextLayer layer];
	self.sequenceNumber.delegate = self;
	
	self.sequenceNumber.font = (__bridge CFTypeRef _Nullable)([NSFont monospacedDigitSystemFontOfSize:48 weight:NSFontWeightBold]);
	self.sequenceNumber.fontSize = 48;
	self.sequenceNumber.foregroundColor = kSequenceNumberColourUnselected.CGColor;
	
	self.sequenceNumber.alignmentMode = kCAAlignmentRight;
	
	[layer addSublayer:self.sequenceNumber];
	
	// set up image layer
	self.imageLayer = [CALayer layer];
	self.imageLayer.delegate = self;
	
	self.imageLayer.borderWidth = 1.f;
	self.imageLayer.borderColor = kPhotoFrameColour.CGColor;
	
	self.imageLayer.masksToBounds = YES;
	self.imageLayer.contentsGravity = kCAGravityResizeAspectFill; // fix any potential gaps or uglies by scaling the image up
	
	[layer addSublayer:self.imageLayer];
	
	// set up image shadow layer
	self.imageShadowLayer = [CALayer layer];
	
	self.imageShadowLayer.shadowColor = [NSColor colorWithCalibratedWhite:0.1 alpha:1.f].CGColor;
	self.imageShadowLayer.shadowRadius = 4.f;
	self.imageShadowLayer.shadowOffset = CGSizeMake(4, -4);
	self.imageShadowLayer.shadowOpacity = 0.2f;
	
	[layer insertSublayer:self.imageShadowLayer below:self.imageLayer];
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
	
	// create the filename label
	self.topInfoFileName = [CATextLayer layer];
	self.topInfoFileName.delegate = self;
	
	self.topInfoFileName.font = (__bridge CFTypeRef _Nullable)([NSFont systemFontOfSize:15 weight:NSFontWeightMedium]);
	self.topInfoFileName.fontSize = 15;
	self.topInfoFileName.foregroundColor = kInfoBoxPrimaryTextColour.CGColor;
	
	self.topInfoFileName.alignmentMode = kCAAlignmentLeft;
	self.topInfoFileName.truncationMode = kCATruncationEnd;
	
	self.topInfoFileName.string = @"really_long_filename.jpg";
	
	self.topInfoFileName.shadowColor = [NSColor blackColor].CGColor;
	self.topInfoFileName.shadowRadius = 2.f;
	self.topInfoFileName.shadowOpacity = 0.15f;
	
	[self.topInfoContainer addSublayer:self.topInfoFileName];
	
	// create the subtitle label
	self.topInfoSubtitle = [CATextLayer layer];
	self.topInfoSubtitle.delegate = self;
	
	self.topInfoSubtitle.font = (__bridge CFTypeRef _Nullable)([NSFont systemFontOfSize:13 weight:NSFontWeightLight]);
	self.topInfoSubtitle.fontSize = 13;
	self.topInfoSubtitle.foregroundColor = kInfoBoxSecondaryTextColour.CGColor;
	
	self.topInfoSubtitle.alignmentMode = kCAAlignmentLeft;
	self.topInfoSubtitle.truncationMode = kCATruncationEnd;
	
	self.topInfoSubtitle.string = @"First row of subtitle information\nSecond row of subtitle information";
	
	[self.topInfoContainer addSublayer:self.topInfoSubtitle];
	
	// create the border that'll show at the bottom of the box
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
	
	// begin a transaction (disabling implicit animations)
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// lay out sequence number
	self.sequenceNumber.frame = CGRectMake(0, frame.size.height - 55, frame.size.width - 8, 52);
	
	// lay out image layer
	CGFloat originalHeight = self.representedObject.rotatedImageSize.height;
	CGFloat originalWidth = self.representedObject.rotatedImageSize.width;
	
	CGFloat xScale = (frame.size.width - (kImageHInset * 2.f) - (kThumbHMargin * 2.f)) / originalWidth;
	CGFloat yScale = (frame.size.height - (kImageVInset) - (kThumbVMargin * 2.f)) / originalHeight;
	
//	CGFloat scale = (originalWidth < originalHeight) ? fminf(xScale, yScale) : fmaxf(xScale, yScale);
	CGFloat scale = fminf(xScale, yScale);
	
	CGFloat finalHeight = originalHeight * scale;
	CGFloat finalWidth = originalWidth * scale;
	
	NSSize imageSize = NSMakeSize(finalWidth, finalHeight);
	
	// center the image in the main layer, and set its frame
	CGFloat imageX = (frame.size.width - imageSize.width) / 2.f;
	CGFloat imageY = (frame.size.height - imageSize.height) / 2.f;
	imageY -= ((kImageVInset - (kImageVInset - kTopInfoBoxHeight)) / 2.f);
	
	self.imageLayer.frame = (CGRect) {
		.size = imageSize,
		.origin = CGPointMake(imageX, imageY)
	};
	self.imageLayer.frame = [self.view backingAlignedRect:self.imageLayer.frame options:NSAlignAllEdgesOutward];
	
	self.imageShadowLayer.frame = self.imageLayer.frame;
	self.imageShadowLayer.shadowPath = CGPathCreateWithRect(self.imageLayer.bounds, NULL);
	
	
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
	
	// commit transaction
	[CATransaction commit];
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
	
	// position the border at the very bottom
	self.topInfoBorder.frame = CGRectMake(0, 1, frame.size.width, 1);
	
	// position the filename and subtitle labels
	self.topInfoFileName.frame = (CGRect) {
		.size = CGSizeMake(frame.size.width - (kInfoBoxHInset * 2.f), 18),
		.origin = CGPointMake(kInfoBoxHInset, kTopInfoBoxHeight - 18 - kInfoBoxVInset)
	};
	
	self.topInfoSubtitle.frame = (CGRect) {
		.size = CGSizeMake(frame.size.width - (kInfoBoxHInset * 2.f), 30),
		.origin = CGPointMake(kInfoBoxHInset, kInfoBoxVInset)
	};
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
	
	// begin a transaction (disabling implicit animations)
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// exit if the property was cleared
	if(image == nil) {
		self.topInfoFileName.string = @"Empty Cell";
		self.topInfoSubtitle.string = @"Empty Cell\nEmpty Cell";
		
		self.imageLayer.contents = nil;
		
		[CATransaction commit];
		return;
	}
	
	// set filename, etc. for top info box
	self.topInfoFileName.string = image.fileUrl.lastPathComponent;
	
	NSString *sizeString = [NSString stringWithFormat:@"%.0f × %.0f", image.rotatedImageSize.width, image.rotatedImageSize.height];
	NSString *shotDateString = [shotDateFormatter stringFromDate:image.dateShot];
	
	self.topInfoSubtitle.string = [NSString stringWithFormat:@"%@\n%@", sizeString, shotDateString];
	
	// do thumbnail images
	[self updateThumbnails];
	
	// commit the transaction
	[CATransaction commit];
}

/**
 * Sets the sequence number field.
 */
- (void) setImageSequence:(NSUInteger) seq {
	_imageSequence = seq;
	
	self.sequenceNumber.string = [NSString stringWithFormat:@"%lu", (unsigned long) seq];
}

#pragma mark Thumb Handling
/**
 * Notification fired when all thumbnails should be invalidated.
 */
- (void) thumbsInvalidatedNotification:(NSNotification *) n {
	[self updateThumbnails];
}

/**
 * Updates the thumbnail image.
 */
- (void) updateThumbnails {
	// request thumbnails
	NSCollectionViewFlowLayout *layout = (NSCollectionViewFlowLayout *) self.collectionView.collectionViewLayout;
	NSSize cellSize = layout.itemSize;
	
	NSSize thumbSz = (NSSize) {
		.width = cellSize.width - (kImageHInset * 2.f),
		.height = cellSize.height - (kImageVInset),
	};
	
	// actually queue the request
	[[TSThumbCache sharedInstance] getThumbForImage:self.representedObject
										   withSize:thumbSz
										andCallback:^(NSImage *thumb) {
		// ensure we only access the image layer on the main thread
		dispatch_async(dispatch_get_main_queue(), ^{
			self.imageLayer.contents = thumb;
		});
	}];
}

@end
