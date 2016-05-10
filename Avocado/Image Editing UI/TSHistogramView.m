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
#import <Accelerate/Accelerate.h>

/// background colour to use for buffers
static const CGFloat TSImageBufBGColour[] = {0, 0, 0, 0};

/// Alpha component for a channel curve's fill
static const CGFloat TSCurveFillAlpha = 0.45f;
/// Alpha component for a channel curve's stroke
static const CGFloat TSCurveStrokeAlpha = 0.75f;

/// Histogram buckets per channel; fixed to 256 since we use 8-bit data.
static const NSUInteger TSHistogramBuckets = 256;

/// KVO context for the image key
static void *TSImageKVOCtx = &TSImageKVOCtx;
/// KVO context for the quality
static void *TSQualityKVOCtx = &TSQualityKVOCtx;

@interface TSHistogramView ()

/// border
@property (nonatomic) CALayer *border;
/// red channel histogram
@property (nonatomic) CAShapeLayer *rLayer;
/// green channel histogram
@property (nonatomic) CAShapeLayer *gLayer;
/// blue channel histogram
@property (nonatomic) CAShapeLayer *bLayer;

/// temporary histogram buffer; straight from vImage
@property (nonatomic) vImagePixelCount *histogram;
/// maximum value for the histomagram in any channel
@property (nonatomic) vImagePixelCount histogramMax;

/// buffer to use for images
@property (nonatomic) vImage_Buffer imgBuf;
/// whether the image buffer is valid
@property (nonatomic) BOOL isImgBufValid;

- (void) setUpLayers;
- (void) setUpCurveLayer:(CAShapeLayer *) curve withChannel:(NSInteger) c;

- (void) allocateBuffers;
- (void) updateImageBuffer;
- (void) updateImageBufferLoadScaled:(BOOL) shouldAllocate;

- (void) layOutSublayers;

- (void) updateDisplay;
- (void) calculateHistogram;
- (void) updateHistogramPaths;

- (CGImageRef) produceScaledVersionForHistogram;

- (NSArray<NSValue *> *) pointsForChannel:(NSUInteger) c;
- (NSBezierPath *) pathForCurvePts:(NSArray<NSValue *> *) points;

@end

@implementation TSHistogramView

- (instancetype) initWithCoder:(NSCoder *)coder {
	if(self = [super initWithCoder:coder]) {
		[self setUpLayers];
		[self allocateBuffers];
		
		self.quality = 4;
		
		// add KVO for properties that cause recomputation of the histogram
		[self addObserver:self forKeyPath:@"image" options:0
				  context:TSImageKVOCtx];
		[self addObserver:self forKeyPath:@"quality" options:0
				  context:TSQualityKVOCtx];
	}
	
	return self;
}

- (instancetype) initWithFrame:(NSRect) frameRect {
	if(self = [super initWithFrame:frameRect]) {
		[self setUpLayers];
		[self allocateBuffers];
		
		self.quality = 4;
		
		// add KVO for properties that cause recomputation of the histogram
		[self addObserver:self forKeyPath:@"image" options:0
				  context:TSImageKVOCtx];
		[self addObserver:self forKeyPath:@"quality" options:0
				  context:TSQualityKVOCtx];
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
	
	self.border.backgroundColor = [NSColor colorWithCalibratedWhite:0.f alpha:0.25].CGColor;
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
	self.histogram = calloc((TSHistogramBuckets * 4), sizeof(vImagePixelCount));
}

/**
 * Invalidates the image buffer.
 */
- (void) invalidateImageBuffer {
	// set buffer state to invalid
	self.isImgBufValid = NO;
	
	// free its memory
	if(self.imgBuf.data != nil) {
		free(self.imgBuf.data);
	}
}

/**
 * Updates the cached vImage buffer for the image.
 */
- (void) updateImageBuffer {
	vImage_Buffer tmpBuf;
	
	// is the buffer valid?
	if(self.isImgBufValid == NO) {
		// if not, allocate a new one.
		[self updateImageBufferLoadScaled:YES];
		return;
	}
	
	
	// check if we need to allocate a new buffer, given this one is valid
	CGFloat factor = 1.f / ((CGFloat) self.quality);
	CGSize newSize = CGSizeApplyAffineTransform(self.image.size, CGAffineTransformMakeScale(factor, factor));
	
	vImageBuffer_Init(&tmpBuf, newSize.height, newSize.width, 32, kvImageNoAllocate);
	
	size_t neededBufSize = tmpBuf.rowBytes * tmpBuf.height;
	size_t oldBufSize = self.imgBuf.rowBytes * self.imgBuf.height;
	
	if(oldBufSize >= neededBufSize) {
		// if not, load the image into the existing buffer
		[self updateImageBufferLoadScaled:NO];
		
		DDLogVerbose(@"Re-used existing image buffer, sz %lu (need %lu)", oldBufSize, neededBufSize);
	} else {
		// otherwise, create a new buffer
		[self invalidateImageBuffer];
		[self updateImageBufferLoadScaled:YES];
		
		DDLogVerbose(@"Allocated new image buffer, sz %lu", neededBufSize);
	}
}

/**
 * Loads the image into the allocated image buffer.
 */
- (void) updateImageBufferLoadScaled:(BOOL) shouldAllocate {
	// create a downscaled version of the image, then a vImage buffer
	CGImageRef img = [self produceScaledVersionForHistogram];
	
	vImage_CGImageFormat format = {
		.version = 0,
		
		.bitsPerComponent = 8,
		.bitsPerPixel = 32,
		.bitmapInfo = (CGBitmapInfo) kCGImageAlphaNoneSkipLast,
		
		.renderingIntent = kCGRenderingIntentDefault,
		.colorSpace = nil,
		
		.decode = NULL
	};
	
	vImageBuffer_InitWithCGImage(&_imgBuf, &format, TSImageBufBGColour,
								 img,
								 shouldAllocate ? kvImageNoFlags : kvImageNoAllocate);
	
	// free image; this frees up memory
	CGImageRelease(img);
	
	// mark buffer as valid
	self.isImgBufValid = YES;
}

/**
 * Frees buffers that were previously manually allocated.
 */
- (void) dealloc {
	// free histogram buffer
	free(self.histogram);
	
	// free image buffer
	[self invalidateImageBuffer];
}

/**
 * KVO handler
 */
- (void) observeValueForKeyPath:(NSString *) keyPath
					   ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	// image changed; update buffer and histogram.
	if(context == TSImageKVOCtx) {
		// update the image buffer with new data
		if(self.image != nil) {
			[self updateImageBuffer];
		}
		
		// update the display
		[self updateDisplay];
	}
	// the quality has changed; update the buffer.
	else if(context == TSQualityKVOCtx) {
		self.isImgBufValid = NO;
		
		// update the image buffer and histogram, if an image is loaded
		if(self.image != nil) {
			[self updateImageBuffer];
			[self updateDisplay];
		} else {
			[self invalidateImageBuffer];
		}
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
- (void) updateDisplay {
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
		[self calculateHistogram];
	});
}

/**
 * Performs calculation of histogram data, scales it, then calculates an
 * interpolated bezier path for each component.
 *
 * @note This _must_ be called on a background thread. It is slow.
 */
- (void) calculateHistogram {	
	NSUInteger i, c;
	
	// calculate the histogram, from already loaded image data
	vImagePixelCount *histogramPtr[] = {
		self.histogram,
		self.histogram + (TSHistogramBuckets * 1),
		self.histogram + (TSHistogramBuckets * 2),
		self.histogram + (TSHistogramBuckets * 3),
	};
	
	vImageHistogramCalculation_ARGB8888(&_imgBuf, histogramPtr, kvImageNoFlags);
	
	// find the maximum value in the buffer
	self.histogramMax = 0;
	
	for(i = 0; i < TSHistogramBuckets; i++) {
		for(c = 0; c < 3; c++) {
			// check if it's higher than the max value
			if(self.histogramMax < histogramPtr[c][i]) {
				self.histogramMax = histogramPtr[c][i];
			}
		}
	}
	
	// draw the histogram paths
	[self updateHistogramPaths];
}

#pragma mark Histogram Display
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
	
	// get the buffer for the histogram
	vImagePixelCount *buffer = self.histogram;
	buffer += (c * TSHistogramBuckets);
	
	// create points for each of the points
	for(NSUInteger i = 0; i < TSHistogramBuckets; i++) {
		// calculate X and Y positions
		CGFloat x = (((CGFloat) i) / ((CGFloat) TSHistogramBuckets - 1) * curveSz.width) - 1.f;
		
		CGFloat y = curveSz.height - (((CGFloat) buffer[i]) / ((CGFloat) self.histogramMax) * curveSz.height);
		
		// make point and store it
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

#pragma mark Helpers
/**
 * Scales the input image by the "quality" factor, such that it can be
 * used to calculate a histogram. If no scaling is to be done (quality = 1)
 * the original image is returned.
 */
- (CGImageRef) produceScaledVersionForHistogram {
	CGContextRef ctx;
	
	// short-circuit if quality == 1
	if(self.quality <= 1) {
		return [self.image CGImageForProposedRect:nil context:nil
											hints:nil];
	}
	
	// calculate scale factor
	CGFloat factor = 1.f / ((CGFloat) self.quality);
	
	CGSize newSize = CGSizeApplyAffineTransform(self.image.size, CGAffineTransformMakeScale(factor, factor));
	
	// get information from the image
	CGImageRef cgImage = [self.image CGImageForProposedRect:nil context:nil
													  hints:nil];
	
	size_t bitsPerComponent = CGImageGetBitsPerComponent(cgImage);
	size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(cgImage);
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(cgImage);
	
	// set up bitmap context
	ctx = CGBitmapContextCreate(nil, newSize.width, newSize.height,
								bitsPerComponent, bytesPerRow, colorSpace,
								bitmapInfo);
	CGContextSetInterpolationQuality(ctx, kCGInterpolationMedium);
	
	CGColorSpaceRelease(colorSpace);
	
	// draw the image pls
	CGRect destRect = {
		.size = newSize,
		.origin = CGPointZero
	};
	
	CGContextDrawImage(ctx, destRect, cgImage);
	
	// create a CGImage from the context, then clean up
	CGImageRef scaledImage = CGBitmapContextCreateImage(ctx);
	
	CGContextRelease(ctx);
	
	// done.
	return scaledImage;
}

@end
