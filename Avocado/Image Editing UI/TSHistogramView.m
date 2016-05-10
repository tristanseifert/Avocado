//
//  TSHistogramView.m
//  Avocado
//
//  Created by Tristan Seifert on 20160510.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSHistogramView.h"
#import "NSBezierPath+AvocadoUtils.h"

#import <Quartz/Quartz.h>
#import <CoreImage/CoreImage.h>

/// how many buckets are in the histogram
static const NSUInteger histogramBuckets = 256;

/// CoreImage context used to calculate histogram; shared
static CIContext *context;
/// KVO context for the image key
void *TSImageKVOCtx = &TSImageKVOCtx;

@interface TSHistogramView ()

/// red histogram
@property (nonatomic) CAShapeLayer *rLayer;
/// green histogram
@property (nonatomic) CAShapeLayer *gLayer;
/// blue histogram
@property (nonatomic) CAShapeLayer *bLayer;

/// border
@property (nonatomic) CALayer *border;

/// when YES, an image has been analyzed
/// histogram data buffer (sizeof(unsigned int) * 4 * 256)
@property (nonatomic) float *rawHistogramData;

/// maximum value for the histomagram
@property (nonatomic) CGFloat histogramMax;

- (void) setUpLayers;
- (void) allocateBuffers;
- (void) layOutSublayers;

- (void) reCalculateHistogram;
- (void) calculateHistogramAndCreatePath;
- (void) updateHistogramPaths;

@end

@implementation TSHistogramView

- (instancetype) initWithCoder:(NSCoder *)coder {
	if(self = [super initWithCoder:coder]) {
		[self setUpLayers];
		[self allocateBuffers];
	}
	
	return self;
}

- (instancetype) initWithFrame:(NSRect) frameRect {
	if(self = [super initWithFrame:frameRect]) {
		[self setUpLayers];
		[self allocateBuffers];
	}
	
	return self;
}

/**
 * Sets up the view's layers.
 */
- (void) setUpLayers {
	self.wantsLayer = YES;
	
	// create layers
	self.border = [CALayer layer];
	
	self.border.borderColor = [NSColor labelColor].CGColor;
	self.border.borderWidth = 1.f;
	
	self.border.backgroundColor = [NSColor colorWithCalibratedWhite:0.f alpha:0.34].CGColor;
	
	self.rLayer = [CAShapeLayer layer];
	self.rLayer.fillColor = [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.35].CGColor;
	self.rLayer.strokeColor = [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.65].CGColor;
	self.rLayer.lineWidth = 1.f;
	
	self.gLayer = [CAShapeLayer layer];
	self.gLayer.fillColor = [NSColor colorWithCalibratedRed:0 green:1 blue:0 alpha:0.35].CGColor;
	self.gLayer.strokeColor = [NSColor colorWithCalibratedRed:0 green:1 blue:0 alpha:0.65].CGColor;
	self.gLayer.lineWidth = 1.f;
	
	self.bLayer = [CAShapeLayer layer];
	self.bLayer.fillColor = [NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:0.35].CGColor;
	self.bLayer.strokeColor = [NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:0.65].CGColor;
	self.bLayer.lineWidth = 1.f;
	
	// flip the Y coordinate system of the curves
	self.border.sublayerTransform = CATransform3DMakeScale(1.0f, -1.0f, 1.0f);
	
	// add layers (stacked such that it's ordered B -> G -> R)
	[self.border addSublayer:self.rLayer];
	[self.border insertSublayer:self.gLayer above:self.rLayer];
	[self.border insertSublayer:self.bLayer above:self.gLayer];
	
	[self.layer addSublayer:self.border];
	
	// set up the shared CoreImage context
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		context = [CIContext contextWithOptions:@{
			// use the software renderer
			kCIContextUseSoftwareRenderer: @YES
		}];
	});
	
	// add KVO for the image key
	[self addObserver:self forKeyPath:@"image" options:0
			  context:TSImageKVOCtx];
}

/**
 * Allocates buffers of raw histogram data.
 */
- (void) allocateBuffers {
	self.rawHistogramData = calloc((histogramBuckets * 4), sizeof(float));
}

/**
 * Frees buffers that were previously manually allocated.
 */
- (void) dealloc {
	free(self.rawHistogramData);
}

/**
 * KVO handler
 */
- (void) observeValueForKeyPath:(NSString *) keyPath
					   ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	if(context == TSImageKVOCtx) {
		[self reCalculateHistogram];
	}
}

#pragma mark Layout
/**
 * Re-aligns layers and updates their contents scale, when the backing
 * store of the view changes.
 */
- (void) viewDidChangeBackingProperties {
	[super viewDidChangeBackingProperties];
}

/**
 * When the view itself participates in Autolayout, lay out the sublayers
 * manually.
 */
- (void) layout {
	[super layout];
	
	[self layOutSublayers];
}

/**
 * Lays out all of the sublayers to fit in the view.
 */
- (void) layOutSublayers {
	NSRect frame = self.bounds;
	
	// begin a transaction (disabling implicit animations)
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// lay out the border
	self.border.frame = frame;
	
	// lay out the things inside
	NSRect curvesFrame = NSInsetRect(frame, 1, 1);
	
	self.rLayer.frame = curvesFrame;
	self.gLayer.frame = curvesFrame;
	self.bLayer.frame = curvesFrame;
	
	// update the histogram paths
	if(self.image != nil) {
		[self updateHistogramPaths];
	}
	
	// commit transaction
	[CATransaction commit];
}

/**
 * Use a flipped coordinate system.
 */
- (BOOL) isFlipped {
	return NO;
}

#pragma mark Histogram Calculation
/**
 * Re-calculates the histogram for the image that was assigned to the
 * control.
 */
- (void) reCalculateHistogram {
	// if the image became nil, hide the histograms
	if(self.image == nil) {
		// set up an animation transaction
		[CATransaction begin];
		[CATransaction setAnimationDuration:0.5];
		[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		
		// set the paths to nil
		self.rLayer.path = nil;
		self.gLayer.path = nil;
		self.bLayer.path = nil;
		
		// commit transaction
		[CATransaction commit];
		
		return;
	}
	
	// queue the calculation on a background thread
	dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
	
	dispatch_async(q, ^{
		[self calculateHistogramAndCreatePath];
	});
}

/**
 * Performs calculation of histogram data, scales it, then calculates an
 * interpolated bezier path for each component.
 *
 * @note This _must_ be called on a background thread. It is slow.
 */
- (void) calculateHistogramAndCreatePath {
	NSUInteger i, c;
	
	// calculate the histogram on the image
	CIFilter *histFilter = [CIFilter filterWithName:@"CIAreaHistogram"];
	
	[histFilter setValue:self.image forKey:kCIInputImageKey];
	[histFilter setValue:[CIVector vectorWithCGRect:self.image.extent]
			forKey:kCIInputExtentKey];
	[histFilter setValue:@(histogramBuckets) forKey:@"inputCount"];
	[histFilter setValue:@1 forKey:kCIInputScaleKey];
	
	CIImage *histogramData = [histFilter valueForKey:kCIOutputImageKey];
	
	
	// render the histogram and maximum data into a buffer, pls
	[context render:histogramData
		   toBitmap:self.rawHistogramData
		   rowBytes:(histogramBuckets * 4 * sizeof(float))
			 bounds:histogramData.extent
			 format:kCIFormatRGBAf colorSpace:nil];
	
	// find which component has the maximum, then multiply all of them
	self.histogramMax = 0.f;
	
	for(i = 0; i < histogramBuckets; i++) {
		for(c = 0; c < 3; c++) {
			// check if it's higher than the max value
			if(self.histogramMax < self.rawHistogramData[(i * 4) + c]) {
				self.histogramMax = self.rawHistogramData[(i * 4) + c];
			}
		}
	}
	
	DDLogVerbose(@"Scaling all components such that max = %f", self.histogramMax);
	
	// draw the histogram paths
	[self updateHistogramPaths];
}

/**
 * Takes the scaled histogram data and turns it into paths.
 */
- (void) updateHistogramPaths {
	NSUInteger i;
	
	// calculate widths, heights and so forth
	NSRect curvesFrame = NSInsetRect(self.bounds, 1, 1);
	CGFloat height = curvesFrame.size.height;
	
	// these arrays will have the points in them
	NSMutableArray<NSValue *> *rPoints = [NSMutableArray new];
	NSMutableArray<NSValue *> *gPoints = [NSMutableArray new];
	NSMutableArray<NSValue *> *bPoints = [NSMutableArray new];
	
	// create points for each of the points
	for(i = 0; i < histogramBuckets; i++) {
		// calculate X
		CGFloat x = ((CGFloat) i) / ((CGFloat) histogramBuckets) * curvesFrame.size.width;

		// do the red component
		CGFloat r = height - (self.rawHistogramData[(i * 4) + 0] / self.histogramMax * height);
		[bPoints addObject:[NSValue valueWithPoint:NSMakePoint(x, r)]];
		
		// do the green component
		CGFloat g = height - (self.rawHistogramData[(i * 4) + 1] / self.histogramMax * height);
		[bPoints addObject:[NSValue valueWithPoint:NSMakePoint(x, g)]];
		
		// do the blue component
		CGFloat b = height - (self.rawHistogramData[(i * 4) + 2] / self.histogramMax * height);
		[bPoints addObject:[NSValue valueWithPoint:NSMakePoint(x, b)]];
	}
	
	// make red path
	NSBezierPath *redPath = [NSBezierPath new];
	[redPath moveToPoint:NSMakePoint(0, curvesFrame.size.height)];
	
	NSBezierPath *redPathPts = [NSBezierPath new];
	[redPathPts interpolatePointsWithHermite:rPoints];
	[redPath appendBezierPath:redPathPts];
	[redPath lineToPoint:NSMakePoint(curvesFrame.size.width, curvesFrame.size.height)];
	[redPath lineToPoint:NSMakePoint(0, curvesFrame.size.height)];
	
	// make green path
	NSBezierPath *greenPath = [NSBezierPath new];
	[greenPath moveToPoint:NSMakePoint(0, curvesFrame.size.height)];
	
	NSBezierPath *greenPathPts = [NSBezierPath new];
	[greenPathPts interpolatePointsWithHermite:gPoints];
	[greenPath appendBezierPath:greenPathPts];
	[greenPath lineToPoint:NSMakePoint(curvesFrame.size.width, curvesFrame.size.height)];
	[greenPath lineToPoint:NSMakePoint(0, curvesFrame.size.height)];
	
	// make blue path
	NSBezierPath *bluePath = [NSBezierPath new];
	[bluePath moveToPoint:NSMakePoint(0, curvesFrame.size.height)];
	
	NSBezierPath *bluePathPts = [NSBezierPath new];
	[bluePathPts interpolatePointsWithHermite:bPoints];
	[bluePath appendBezierPath:bluePathPts];
	[bluePath lineToPoint:NSMakePoint(curvesFrame.size.width, curvesFrame.size.height)];
	[bluePath lineToPoint:NSMakePoint(0, curvesFrame.size.height)];
	
	// set the paths on the main thread, with animation
	dispatch_async(dispatch_get_main_queue(), ^{
		// set up an animation transaction
		[CATransaction begin];
		[CATransaction setAnimationDuration:0.5];
		[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		
		self.rLayer.path = redPath.CGPath;
		self.gLayer.path = greenPath.CGPath;
		self.bLayer.path = bluePath.CGPath;
		
		// commit transaction
		[CATransaction commit];
	});
	
//	DDLogVerbose(@"R: %@", rPoints);
//	DDLogVerbose(@"G: %@", gPoints);
//	DDLogVerbose(@"B: %@ (%li)", bPoints, bPoints.count);
}

@end
