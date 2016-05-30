//
//  TSRawThumbExtractor.m
//  Avocado
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSRawThumbExtractor.h"

#import "libraw.h"

#import <Accelerate/Accelerate.h>

/**
 * The combination of rotation and flipping required to transform an image to
 * match display to the given EXIF data is specified by the arrays below.
 *
 * (Note: Below each image is the rotation/flip to translate to image 1)
 *
 *   1        2       3      4         5            6           7          8
 *
 * ██████  ██████      ██  ██      ██████████  ██                  ██  ██████████
 * ██          ██      ██  ██      ██  ██      ██  ██          ██  ██      ██  ██
 * ████      ████    ████  ████    ██          ██████████  ██████████          ██
 * ██          ██      ██  ██
 * ██          ██  ██████  ██████
 *
 *		   000°/V  000°/H  180°/V  270°/V      090°/x       090°/V     090°/H
 *
 * Positive rotation values are interpreted to mean counterclockwise rotation.
 *
 * The first entry in the array is rotation (in degrees) while the second entry
 * is the flip value; 0 is no flip, 1 is vertical, 2 is horizontal.
 */
static const NSInteger TSEXIFTransformData[][2] = {
	{  0, 0},	// 1
	{  0, 1},	// 2
	{  0, 2},	// 3
	{180, 1},	// 4
	{270, 1},	// 5
	{ 90, 0},	// 6
	{ 90, 1},	// 7
	{ 90, 2},	// 8
};

@interface TSRawThumbExtractor ()

/// Extracted main (largest) thumbnail
@property (nonatomic) CGImageRef extractedThumb;

/// LibRaw handle for this image
@property (nonatomic, assign) libraw_data_t *libRaw;

- (CGImageRef) fliptateImage:(CGImageRef) inImage withOrientation:(NSUInteger) orientation;

- (NSError *) errorFromCode:(int) code;

@end

@implementation TSRawThumbExtractor


/**
 * Initializes the thumb extractor, given the url to the input file. Returns
 * nil if the file could not be loaded.
 */
- (instancetype) initWithRawFile:(NSURL *) url {
	if(self = [super init]) {
		int lrErr = 0;
		
		// Attempt to load the image directly from disk (LibRaw does IO)
		NSString *path = url.path;
		const char *fsPath = path.fileSystemRepresentation;
		
		self.libRaw = libraw_init(0);
		
		if((lrErr = libraw_open_file(self.libRaw, fsPath)) != LIBRAW_SUCCESS) {
			NSError *nsErr = [self errorFromCode:lrErr];
			
			DDLogError(@"Couldn't open raw file at %@: %@", url, nsErr);
			return nil;
		}
		
		// Unpack thumbnail data
		if((lrErr = libraw_unpack_thumb(self.libRaw)) != LIBRAW_SUCCESS) {
			NSError *nsErr = [self errorFromCode:lrErr];
			
			DDLogError(@"Couldn't unpack thumb: %@", nsErr);
			return nil;
		}
	}
	
	return self;
}

/**
 * Releases LibRaw resources back to the system when deallocating.
 */
- (void) dealloc {
	// Close LibRaw handle
	libraw_close(self.libRaw);
	
	// If the thumbnail was extracted, realease it, too
	if(self.extractedThumb != nil) {
		CGImageRelease(self.extractedThumb);
		self.extractedThumb = nil;
	}
}

/**
 * Extracts a thumbnail of the given size from the raw file. If there are
 * multiple thumbnails present, the largest one, closest to the given size is
 * returned. Otherwise, the existing thumbnail is downscaled (if the size is
 * smaller than its size) or returned as-is.
 */
- (CGImageRef) extractThumbWithSize:(CGFloat) thumbSize {
	CGContextRef ctx;
	
	// Extract full-size thumbnail data, if necessary
	if(self.extractedThumb == nil) {
		[self convertEmbeddedThumbnail];
	}
	
	// Calculate new size of the image
	CGFloat oldWidth = CGImageGetWidth(self.extractedThumb);
	CGFloat oldHeight = CGImageGetHeight(self.extractedThumb);
	
	CGFloat scaleFactor = (oldWidth > oldHeight) ? thumbSize / oldWidth : thumbSize / oldHeight;
	
	CGFloat newHeight = oldHeight * scaleFactor;
	CGFloat newWidth = oldWidth * scaleFactor;
	CGSize newSize = CGSizeMake(newWidth, newHeight);
	
	// Set up a bitmap context into which to draw the downscaled image
	size_t bitsPerComponent = CGImageGetBitsPerComponent(self.extractedThumb);
	size_t bitsPerPixel = CGImageGetBitsPerPixel(self.extractedThumb);
	size_t bytesPerRow = (bitsPerPixel / 8) * newSize.width;
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(self.extractedThumb);
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(self.extractedThumb);
	
	ctx = CGBitmapContextCreate(nil, newSize.width, newSize.height,
								bitsPerComponent, bytesPerRow, colorSpace,
								bitmapInfo);
	
	// Don't release the colour space; this can cause crashes later? (shared colour space object?)
//	CGColorSpaceRelease(colorSpace);
	
	// Prepare for drawing in the context (set up interpolation quality)
	CGContextSetInterpolationQuality(ctx, kCGInterpolationMedium);
	CGContextSetAllowsAntialiasing(ctx, YES);
	
	// Draw original image into the context
	CGRect destRect = {
		.size = newSize,
		.origin = CGPointZero
	};
	
	CGContextDrawImage(ctx, destRect, self.extractedThumb);
	
	// Create a CGImage from the context, and clean up
	CGImageRef scaledImage = CGBitmapContextCreateImage(ctx);
	CGContextRelease(ctx);
	
	// If needed, rotate the image
	NSUInteger flip = self.libRaw->sizes.flip;
	
	if(flip != 0) {
		return [self fliptateImage:scaledImage withOrientation:flip];
	} else {
		return scaledImage;
	}
}

/**
 * Rotates and flips the given CGImage, according to the specified orientation
 * value; it is the same as the EXIF orientation tag.
 *
 * If this function fails (perhaps due to memory constraints, or an internal
 * library error,) it will return the input image.
 */
- (CGImageRef) fliptateImage:(CGImageRef) inImage withOrientation:(NSUInteger) orientation {
	vImage_Error err;
	
	// Shortcut if orientation is zero.
	if(orientation == 0) {
		return inImage;
	}
	
	DDLogVerbose(@"EXIF rotation = %li; rotate by %li°, flip = %li", orientation, TSEXIFTransformData[orientation][0], TSEXIFTransformData[orientation][1]);
	
	
	/*
	 * Create a temporary input buffer for the vImage transform functions from
	 * the passed in CGImage. This may or may not convert pixel data, but it
	 * will always allocate a new buffer.
	 */
	vImage_Buffer inBuf, outBuf;
	vImage_CGImageFormat cgFormat;
	
	cgFormat.bitsPerComponent = (uint32_t) CGImageGetBitsPerComponent(inImage);
	cgFormat.bitsPerPixel = (uint32_t) CGImageGetBitsPerPixel(inImage);
	cgFormat.colorSpace = CGImageGetColorSpace(inImage);
	cgFormat.bitmapInfo = CGImageGetBitmapInfo(inImage);
	cgFormat.version = 0; // may change in the future
	cgFormat.decode = NULL;
	cgFormat.renderingIntent = kCGRenderingIntentPerceptual;
	
	err = vImageBuffer_InitWithCGImage(&inBuf, &cgFormat, NULL, inImage, kvImageNoFlags);
	
	if(err != kvImageNoError) {
		DDLogError(@"vImageBuffer_InitWithCGImage failed: %zi", err);
		return inImage;
	}
	
	
	/*
	 * Allocate a secondary output buffer. Neither the rotation nor flipping can
	 * operate in-place, so they will need to render into a buffer different
	 * than the one they read from.
	 *
	 * If rotation is taking place, AND it is not 180°, the width and height
	 * values are swapped, so that the rotation functions work.
	 */
	vImagePixelCount width = CGImageGetWidth(inImage);
	vImagePixelCount height = CGImageGetHeight(inImage);
	
	if(TSEXIFTransformData[orientation][0] != 0 && TSEXIFTransformData[orientation][0] != 180) {
		width = CGImageGetHeight(inImage);
		height = CGImageGetWidth(inImage);
		
		DDLogVerbose(@"Flipping height and width of output buffer for rotation: {w = %li, h = %li}", width, height);
	}
	
	err = vImageBuffer_Init(&outBuf, height, width, cgFormat.bitsPerPixel, kvImageNoFlags);
	
	if(err != kvImageNoError) {
		DDLogError(@"vImageBuffer_Init failed: %zi", err);
		
		free(inBuf.data);
		return inImage;
	}
	
	
	// Rotate image, if needed.
	if(TSEXIFTransformData[orientation][0] != 0) {
		// Figure out the angle, in radians
		CGFloat degrees = (CGFloat) TSEXIFTransformData[orientation][0];
		CGFloat angle = (degrees * M_PI / 180.0);
		
		// Perform rotation
		uint8_t background[] = {0, 0, 0, 0xFF};
		err = vImageRotate_ARGB8888(&inBuf, &outBuf, NULL, angle,
									(uint8_t *) &background, kvImageBackgroundColorFill);
		
		// Handle any errors vImage may have raised.
		if(err != kvImageNoError) {
			DDLogError(@"vImageRotate_ARGB8888 failed: %zi", err);
			
			free(inBuf.data);
			free(outBuf.data);
			return inImage;
		}
	}
	/*
	 * If no rotation was needed, switch the input and output buffer structs.
	 * Since the case of no rotation or flipping (orientation 1) is protected
	 * against at the very start of the function, this should only ever be
	 * called if there will be flipping later on.
	 *
	 * The flipping code below expects pixel data to be in outBuf, but since the
	 * rotation functions didn't run and copy the data there, instead switch the
	 * input and output buffers. The original output buffer is now in inBuf, and
	 * the input image buffer is in outBuf. This causes the original input
	 * buffer to be deallocated later.
	 */
	else {
		vImage_Buffer inputDataBuf = inBuf;
		vImage_Buffer outputDataBuf = outBuf;
		
		outBuf = inputDataBuf;
		inBuf = outputDataBuf;
	}
	
	
	// Flip image, if needed.
	if(TSEXIFTransformData[orientation][1] != 0) {
		// Vertical flip
		if(TSEXIFTransformData[orientation][1] == 1) {
			err = vImageVerticalReflect_ARGB8888(&outBuf, &inBuf, kvImageNoFlags);
		}
		// Horizontal flip
		if(TSEXIFTransformData[orientation][1] == 2) {
			err = vImageHorizontalReflect_ARGB8888(&outBuf, &inBuf, kvImageNoFlags);
		}
		
		// Handle any errors vImage may have raised.
		if(err != kvImageNoError) {
			DDLogError(@"vImage[Vertical/Horizontal]Reflect_ARGB8888 failed: %zi", err);
			
			free(inBuf.data);
			free(outBuf.data);
			return inImage;
		}
	}
	/*
	 * If no flipping was needed, switch the output and input buffer structs.
	 * Since the case of no rotation or flipping (orientation 1) is protected
	 * against at the very start of the function, this should only ever be
	 * called if there WAS rotation.
	 *
	 * Thus, rotated image data is in outBuf. The below code requires it to be
	 * in inBuf, so swap the two buffers. This causes the original input buffer
	 * to be deallocated later.
	 */
	else {
		vImage_Buffer inputDataBuf = inBuf;
		vImage_Buffer outputDataBuf = outBuf;
		
		outBuf = inputDataBuf;
		inBuf = outputDataBuf;
	}
	
	
	/*
	 * Convert the vImage buffer created from the input buffer back to a CGImage
	 * to display. The `kvImageNoAllocate` flag forces it to operate in no-copy
	 * mode, where the original buffer's memory is simply transferred to the
	 * CGImage instance.
	 *
	 * The third argument specifies a deallocation callback function; because we
	 * specify NULL, vImage will call free() on the previous buffer when it is
	 * no longer needed.
	 *
	 * Also, free the memory of whatever buffer isn't the final buffer passed to
	 * the image creation call. This should always be in outBuf. Lastly, free
	 * the input image, as it is no longer needed.
	 */
	free(outBuf.data);
	CGImageRelease(inImage);
	
	return vImageCreateCGImageFromBuffer(&inBuf, &cgFormat, NULL, NULL, kvImageNoAllocate, &err);
}

#pragma mark Thumb Handling
/**
 * Converts the thumbnail from whatever format is stored within the RAW image
 * to an NSImage.
 */
- (void) convertEmbeddedThumbnail {
	// Pointer because this is way too fucking long to keep repeating
	enum LibRaw_thumbnail_formats format = self.libRaw->thumbnail.tformat;
	
	// Create an NSData from the pointer to the thumb data w/o copying bytes
	NSData *data = [NSData dataWithBytesNoCopy:self.libRaw->thumbnail.thumb
										length:self.libRaw->thumbnail.tlength
								  freeWhenDone:NO];
	
	
	switch(format) {
		/// Embedded JPEG thumbnail
		case LIBRAW_THUMBNAIL_JPEG: {
			CGDataProviderRef provider;
			
			// Create a data provider, given the input data
			provider = CGDataProviderCreateWithCFData((__bridge CFDataRef) data);
			
			// Create an image from it, rotating it if necessary
			self.extractedThumb = CGImageCreateWithJPEGDataProvider(provider, nil, YES, kCGRenderingIntentPerceptual);
			
			// TODO: Rotate image (self.libRaw->sizes.flip)
			
			// Clean up
			CGDataProviderRelease(provider);
			
			break;
		}
			
		/// Raw bitmap data (currently unsupported)
//		case LIBRAW_THUMBNAIL_BITMAP:
//			break;
			
		default:
			DDLogError(@"Unsupported thumbnail format: %u", format);
			break;
	}
}

#pragma mark Helpers
/**
 * Creates an NSError object from a LibRaw error. Positive error codes are
 * directly from the system, and are treated as POSIX errors. Negative codes
 * are LibRAW errors.
 */
- (NSError *) errorFromCode:(int) code {
	NSError *err = nil;
	NSDictionary *info = nil;
	NSString *codeInfo = nil;
	
	if(code == 0) return nil;
	
	if(code > 0) {
		// create a POSIX error
		codeInfo = [NSString stringWithCString:strerror(code)
									  encoding:NSUTF8StringEncoding];
		
		info = @{
			NSLocalizedDescriptionKey: codeInfo
		};
		err = [NSError errorWithDomain:NSPOSIXErrorDomain code:code
							  userInfo:info];
	} else {
		// create a custom RAW library error object
		codeInfo = [NSString stringWithCString:libraw_strerror(code)
									  encoding:NSUTF8StringEncoding];
		
		info = @{
			NSLocalizedDescriptionKey: codeInfo
		};
		err = [NSError errorWithDomain:NSPOSIXErrorDomain code:code
							  userInfo:info];
	}
	
	// return the created error
	return err;
}


@end
