//
//  TSRawThumbExtractor.m
//  Avocado
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSRawThumbExtractor.h"

#import "libraw.h"
#import "TSImageTransformHelpers.h"

#import <Accelerate/Accelerate.h>

NSString *const TSRawImageErrorDomain = @"TSRawImageErrorDomain";
NSString *const TSRawImageErrorIsFatalKey = @"TSRawImageErrorIsFatal";

static void TSRawThumbExtractorReleaseDirect(void *info, const void *data, size_t size);

@interface TSRawThumbExtractor ()

/// Extracted main (largest) thumbnail
@property (nonatomic) CGImageRef extractedThumb;
/// Set if a thumbnail could be extracted; NO otherwise.
@property (nonatomic) BOOL couldExtractValidThumb;

/// LibRaw handle for this image
@property (nonatomic, assign) libraw_data_t *libRaw;
/// URL from which the image was loaded
@property (nonatomic) NSURL *fileUrl;

- (NSError *) errorFromCode:(int) code;

@end

@implementation TSRawThumbExtractor


/**
 * Initializes the thumb extractor, given the url to the input file. Returns
 * nil if the file could not be loaded.
 */
- (instancetype) initWithRawFile:(NSURL *) url andError:(NSError **) outErr {
	if(self = [super init]) {
		int lrErr = 0;
		self.fileUrl = url;
		
		// Attempt to load the image directly from disk (LibRaw does IO)
		NSString *path = self.fileUrl.path;
		const char *fsPath = path.fileSystemRepresentation;
		
		self.libRaw = libraw_init(0);
		
		if((lrErr = libraw_open_file(self.libRaw, fsPath)) != LIBRAW_SUCCESS) {
			NSError *nsErr = [self errorFromCode:lrErr];
			
			if(outErr) *outErr = nsErr;
			else  DDLogError(@"Couldn't open raw file at %@: %@", url, nsErr);
			
			return nil;
		}
		
		// Unpack thumbnail data
		if((lrErr = libraw_unpack_thumb(self.libRaw)) != LIBRAW_SUCCESS) {
			NSError *nsErr = [self errorFromCode:lrErr];
			
			if(outErr) *outErr = nsErr;
			else DDLogError(@"Couldn't unpack thumb: %@", nsErr);
			
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
	
	// Was a valid thumbnail image extracted?
	if(self.couldExtractValidThumb == NO) {
		return nil;
	}
	
	// Calculate new size of the image (use ceil to round up)
	CGFloat oldWidth = CGImageGetWidth(self.extractedThumb);
	CGFloat oldHeight = CGImageGetHeight(self.extractedThumb);
	
	CGFloat scaleFactor = (oldWidth > oldHeight) ? thumbSize / oldWidth : thumbSize / oldHeight;
	
	// If the scale factor is GREATER than 1.0 (embiggenment) just return the image
	if(scaleFactor > 1.f) {
		NSUInteger flip = self.libRaw->sizes.flip;
		CGImageRef extractedImg = CGImageRetain(self.extractedThumb);
		
		if(flip != 0) {
			return TSFliptateImageWithEXIFOrientation(extractedImg, flip);
		} else {
			return extractedImg;
		}
	}
	
	// Calculate scaled size of the image
	CGFloat newHeight = ceil(oldHeight * scaleFactor);
	CGFloat newWidth = ceil(oldWidth * scaleFactor);
	CGSize newSize = CGSizeMake(newWidth, newHeight);
	
	// Set up a bitmap context into which to draw the downscaled image
	size_t bitsPerComponent = CGImageGetBitsPerComponent(self.extractedThumb);
	size_t bitsPerPixel = CGImageGetBitsPerPixel(self.extractedThumb);
	size_t bytesPerRow = (bitsPerPixel / 8) * newWidth;
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
		return TSFliptateImageWithEXIFOrientation(scaledImage, flip);
	} else {
		return scaledImage;
	}
}

#pragma mark Thumb Handling
/**
 * Converts the thumbnail from whatever format is stored within the RAW image
 * to an NSImage.
 */
- (void) convertEmbeddedThumbnail {
	// Pointer because this is way too fucking long to keep repeating
	enum LibRaw_thumbnail_formats format = self.libRaw->thumbnail.tformat;
	
	// Determine what to do for the given format.
	switch(format) {
		/// Embedded JPEG thumbnail
		case LIBRAW_THUMBNAIL_JPEG: {
			CGDataProviderRef provider;
			
			// Create a data provider, given the input data, then make an image
			provider = CGDataProviderCreateWithData(NULL, self.libRaw->thumbnail.thumb,
													self.libRaw->thumbnail.tlength,
													NULL);
			self.extractedThumb = CGImageCreateWithJPEGDataProvider(provider, nil, YES, kCGRenderingIntentPerceptual);
			
			self.couldExtractValidThumb = YES;
			
			// Clean up
			CGDataProviderRelease(provider);
			
			break;
		}
			
		/// Raw bitmap data (currently unsupported)
		case LIBRAW_THUMBNAIL_BITMAP: {
			vImage_Error err = kvImageNoError;
			CGDataProviderRef provider;
			CGColorSpaceRef cs;
			
			// Get some info for the image
			NSUInteger width = self.libRaw->thumbnail.twidth;
			NSUInteger height = self.libRaw->thumbnail.theight;
			
			
			// Create vImage buffers for RGB888 -> RGBA8888 conversion
			vImage_Buffer inBuf, outBuf;
			
			inBuf.data = self.libRaw->thumbnail.thumb;
			inBuf.rowBytes = width * 3;
			inBuf.width = width;
			inBuf.height = height;
			
			err = vImageBuffer_Init(&outBuf, height, width, 32, kvImageNoFlags);
			NSUInteger outBufSz = (outBuf.rowBytes * outBuf.height);
			
			if(err != kvImageNoError) {
				DDLogError(@"vImageBuffer_Init failed: %zi", err);
				return;
			}
			
			// Convert RGB888 -> RGBA8888
			err = vImageConvert_RGB888toRGBA8888(&inBuf, NULL, 0xFF, &outBuf, NO, kvImageNoFlags);
			
			if(err != kvImageNoError) {
				DDLogError(@"vImageConvert_RGB888toRGBA8888 failed: %zi", err);
				return;
			}
			
			
			// Create a bitmap image from the (converted) data.
			provider = CGDataProviderCreateWithData(NULL, outBuf.data, outBufSz,
													TSRawThumbExtractorReleaseDirect);
			cs = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
			
			self.extractedThumb = CGImageCreate(width, height, 8, 32,
												outBuf.rowBytes, cs,
												(CGBitmapInfo) kCGImageAlphaNoneSkipLast,
												provider, nil, true,
												kCGRenderingIntentPerceptual);
			self.couldExtractValidThumb = YES;
			
			// Clean up some state
			CGDataProviderRelease(provider);
			CGColorSpaceRelease(cs);
			
			break;
		}
			
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
			NSLocalizedDescriptionKey: codeInfo,
			TSRawImageErrorIsFatalKey: @(LIBRAW_FATAL_ERROR(code))
		};
		err = [NSError errorWithDomain:NSPOSIXErrorDomain code:code
							  userInfo:info];
	} else {
		// create a custom RAW library error object
		codeInfo = [NSString stringWithCString:libraw_strerror(code)
									  encoding:NSUTF8StringEncoding];
		
		info = @{
			NSLocalizedDescriptionKey: codeInfo,
			TSRawImageErrorIsFatalKey: @(LIBRAW_FATAL_ERROR(code))
		};
		err = [NSError errorWithDomain:TSRawImageErrorDomain code:code
							  userInfo:info];
	}
	
	// return the created error
	return err;
}

@end

/**
 * Releases directly accessed Quartz pixel data.
 */
static void TSRawThumbExtractorReleaseDirect(void *info, const void *data, size_t size) {
	free((void *) data);
}
