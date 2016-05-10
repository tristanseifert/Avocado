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

/// test data for the histogram
static float testData[] = {
	0.05, 0.01, 0.02, 0.12, 0.04, 0.05, 0.12, 0.22,
	0.57, 0.12, 0.04, 0.03, 0.04, 0.10, 0.04, 0.14,
	0.24, 0.04
};

/// Alpha component for a channel curve's fill
static const CGFloat TSCurveFillAlpha = 0.45f;
/// Alpha component for a channel curve's stroke
static const CGFloat TSCurveStrokeAlpha = 0.75f;

/// how many buckets are in the histogram
static const NSUInteger TSHistogramBuckets = 256;

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

/// downscaled image to use for histogram
@property (nonatomic) CIImage *downscaledImage;
/// histogram data buffer; percentage of pixels in that bin
@property (nonatomic) float *rawHistogramData;

/// maximum value for the histomagram
@property (nonatomic) CGFloat histogramMax;

/// internal histogram

- (void) setUpLayers;
- (void) setUpCurveLayer:(CAShapeLayer *) curve withChannel:(NSInteger) c;

- (void) allocateBuffers;
- (void) layOutSublayers;

- (void) reCalculateHistogram;
- (void) calculateHistogramAndCreatePath;
- (void) updateHistogramPaths;

- (NSArray<NSValue *> *) pointsForChannel:(NSUInteger) c;
- (NSBezierPath *) pathForCurvePts:(NSArray<NSValue *> *) points;

@end

@implementation TSHistogramView

- (instancetype) initWithCoder:(NSCoder *)coder {
	if(self = [super initWithCoder:coder]) {
		[self setUpLayers];
		[self allocateBuffers];
		
		self.quality = 4;
	}
	
	return self;
}

- (instancetype) initWithFrame:(NSRect) frameRect {
	if(self = [super initWithFrame:frameRect]) {
		[self setUpLayers];
		[self allocateBuffers];
		
		self.quality = 4;
	}
	
	return self;
}

#pragma mark Layers
/**
 * Sets up the view's layers.
 */
- (void) setUpLayers {
	self.wantsLayer = YES;
	
	// create border (also, histogram container)
	self.border = [CALayer layer];
	
	self.border.borderColor = [NSColor labelColor].CGColor;
	self.border.borderWidth = 1.f;
	
	self.border.backgroundColor = [NSColor colorWithCalibratedWhite:0.f alpha:0.3].CGColor;
	self.border.cornerRadius = 2.f;
	self.border.masksToBounds = YES;
	
	// flip the Y coordinate system of the curves
	self.border.sublayerTransform = CATransform3DMakeScale(1.0f, -1.0f, 1.0f);
	
	// set up the curve layers
	self.rLayer = [CAShapeLayer layer];
	self.gLayer = [CAShapeLayer layer];
	self.bLayer = [CAShapeLayer layer];
	
	[self setUpCurveLayer:self.rLayer withChannel:0];
	[self setUpCurveLayer:self.gLayer withChannel:1];
	[self setUpCurveLayer:self.bLayer withChannel:2];
	
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
 * Sets up a curve layer.
 */
- (void) setUpCurveLayer:(CAShapeLayer *) curve withChannel:(NSInteger) c {
	// calculate colours
	CGFloat r, g, b;
	
	r = (c == 0) ? 1.f : 0.f;
	g = (c == 1) ? 1.f : 0.f;
	b = (c == 2) ? 1.f : 0.f;
	
	// set the fills
	curve.fillColor = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:TSCurveFillAlpha].CGColor;
	curve.strokeColor = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:TSCurveStrokeAlpha].CGColor;
	
	curve.lineWidth = 1.f;
	curve.masksToBounds = YES;
	
}

#pragma mark Buffers
/**
 * Allocates buffers of raw histogram data.
 */
- (void) allocateBuffers {
	self.rawHistogramData = calloc((TSHistogramBuckets * 4), sizeof(float));
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
	
	self.layer.contentsScale = self.window.backingScaleFactor;
	
	self.border.contentsScale = self.window.backingScaleFactor;
	
	self.rLayer.contentsScale = self.window.backingScaleFactor;
	self.gLayer.contentsScale = self.window.backingScaleFactor;
	self.bLayer.contentsScale = self.window.backingScaleFactor;
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
	
	// commit transaction
	[CATransaction commit];
	
	// update the histogram paths
	if(self.image != nil) {
		[self updateHistogramPaths];
	}
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
		dispatch_async(dispatch_get_main_queue(), ^{
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
		});
		
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
	[histFilter setValue:@(TSHistogramBuckets) forKey:@"inputCount"];
	[histFilter setValue:@1 forKey:kCIInputScaleKey];
	
	CIImage *histogramData = [histFilter valueForKey:kCIOutputImageKey];
	
	
	// render the histogram and maximum data into a buffer, pls
	[context render:histogramData
		   toBitmap:self.rawHistogramData
		   rowBytes:(TSHistogramBuckets * 4 * sizeof(float))
			 bounds:histogramData.extent
			 format:kCIFormatRGBAf colorSpace:nil];
	
	// find which component has the maximum, then multiply all of them
	self.histogramMax = 0.f;
	
	for(i = 0; i < TSHistogramBuckets; i++) {
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
	// get points for each channel
	NSArray *rPoints = [self pointsForChannel:0];
	NSArray *gPoints = [self pointsForChannel:1];
	NSArray *bPoints = [self pointsForChannel:2];
	
	// make the paths
	NSBezierPath *redPath = [self pathForCurvePts:rPoints];
	NSBezierPath *greenPath = [self pathForCurvePts:gPoints];
	NSBezierPath *bluePath = [self pathForCurvePts:bPoints];
	
	// set the paths on the main thread, with animation
	dispatch_async(dispatch_get_main_queue(), ^{
		// set up an animation transaction
		[CATransaction begin];
		[CATransaction setAnimationDuration:0.66];
		[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		
		self.rLayer.path = redPath.CGPath;
		self.gLayer.path = greenPath.CGPath;
		self.bLayer.path = bluePath.CGPath;
		
		// commit transaction
		[CATransaction commit];
	});
}

/**
 * Creates an array of points, given a channel of the histogram.
 */
- (NSArray<NSValue *> *) pointsForChannel:(NSUInteger) c {
	NSMutableArray<NSValue *> *points = [NSMutableArray new];
	NSSize curveSz = NSInsetRect(self.bounds, 0, 0).size;
	
	// create points for each of the points
	for(NSUInteger i = 0; i < TSHistogramBuckets; i++) {
		// calculate X
		CGFloat x = (((CGFloat) i) / ((CGFloat) TSHistogramBuckets - 1) * curveSz.width) - 1.f;
		
		// calculate y
		CGFloat y = curveSz.height - (self.rawHistogramData[(i * 4) + c] / self.histogramMax * curveSz.height);
		[points addObject:[NSValue valueWithPoint:NSMakePoint(x, y)]];
	}
	
	// done
	return [points copy];
}

/**
 * Makes a path for a curve, given a set of points.
 */
- (NSBezierPath *) pathForCurvePts:(NSArray<NSValue *> *) points {
	NSSize curveSz = NSInsetRect(self.bounds, 0, 0).size;
	
	// start the main path
	NSBezierPath *path = [NSBezierPath new];
	[path moveToPoint:NSMakePoint(0, curveSz.height)];
	
	// append the interpolated points
	NSBezierPath *curvePath = [NSBezierPath new];
	[curvePath interpolatePointsWithHermite:points];
	[path appendBezierPath:curvePath];
	
	// close the path
	[path lineToPoint:NSMakePoint(curveSz.width, curveSz.height)];
	[path lineToPoint:NSMakePoint(0, curveSz.height)];
	
	// done
	return path;
}

@end
