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

@interface TSRawThumbExtractor ()

/// Extracted main (largest) thumbnail
@property (nonatomic) CGImageRef extractedThumb;

/// LibRaw handle for this image
@property (nonatomic, assign) libraw_data_t *libRaw;

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
