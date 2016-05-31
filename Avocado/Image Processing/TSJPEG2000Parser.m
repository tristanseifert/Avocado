//
//  TSJPEG2000Parser.m
//  Avocado
//
//  Created by Tristan Seifert on 20160531.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Accelerate/Accelerate.h>

#import "TSJPEG2000Parser.h"

#import "openjpeg.h"

static inline void TSConvertOpenJPEGTo8BitInPlace(uint32_t *inBuf, NSUInteger width, NSUInteger height);
static inline void TSConvertOpenJPEGTo16BitInPlace(uint32_t *inBuf, NSUInteger width, NSUInteger height);

@interface TSJPEG2000Parser ()

+ (opj_stream_t *) openJPEGStreamForUrl:(NSURL *) url;
+ (NSBitmapImageRep *) bitmapRepForOpenJPEGImage:(opj_image_t *) inImage;

@end

@implementation TSJPEG2000Parser

/**
 * Loads and decodes the full quality JPEG2000 bitstream from the given url, and
 * returns an image with its contents.
 */
+ (NSImage *) jpeg2kFromUrl:(NSURL *) url {
	return [[self class] jpeg2kFromUrl:url withQualityLayer:0];
}

/**
 * Loads and decodes a lower-quality version of the given JPEG2000 bitstream at
 * the given URL. The scale factor can be thought of as the number of times the
 * size is cut in half: 0 is full size, 1 is 1/2, 2 is 1/4, 3 is 1/8, and so
 * forth.
 */
+ (NSImage *) jpeg2kFromUrl:(NSURL *) url withQualityLayer:(NSUInteger) layer {
	opj_stream_t *inStream;
	opj_codec_t *codec;
	opj_dparameters_t parameters;
	
	// This is where the output image is sepulched
	opj_image_t *image = NULL;
	
	// Create both the decompressor and input stream
	inStream = [[self class] openJPEGStreamForUrl:url];
	codec = opj_create_decompress(OPJ_CODEC_JP2);
	
	// Set up the decoder
	parameters.cp_reduce = (OPJ_UINT32) layer;
	parameters.cp_layer = 0;
	
	if(opj_setup_decoder(codec, &parameters) == NO) {
		DDLogError(@"opj_setup_decoder failed for %@", url);
		
		// Clean up some data that may have been allocated
		opj_stream_destroy(inStream);
		opj_destroy_codec(codec);
		
		return nil;
	}
	
	// Read the header of the image
	if(opj_read_header(inStream, codec, &image) == NO) {
		DDLogError(@"opj_read_header failed for %@", url);
		
		// Clean up some data that may have been allocated
		opj_stream_destroy(inStream);
		opj_destroy_codec(codec);
		opj_image_destroy(image);
		
		return nil;
	}
	
	// Decode the area of the entire image
	if(opj_decode(codec, inStream, image) == NO) {
		DDLogError(@"opj_decode failed for %@", url);
		
		// Clean up some data that may have been allocated
		opj_stream_destroy(inStream);
		opj_destroy_codec(codec);
		opj_image_destroy(image);
		
		return nil;
	}
	
	// Destroy the input stream (closes the file)
	opj_stream_destroy(inStream);
	
	// Create a tagged NSImage from the contents of the bitmap
	NSBitmapImageRep *bitmap = [[self class] bitmapRepForOpenJPEGImage:image];

	NSSize imageSize = { .width = image->comps[0].w, .height = image->comps[0].h };
	NSImage *img = [[NSImage alloc] initWithSize:imageSize];
	
	[img addRepresentation:bitmap];
	
	
	// Clean up some more stuff
	opj_destroy_codec(codec);
	opj_image_destroy(image);
	
	// Return an NSImage created from the given CGImage
	return img;
}

#pragma mark Helpers
/**
 * Creates an OpenJPEG stream from the file at the given url.
 */
+ (opj_stream_t *) openJPEGStreamForUrl:(NSURL *) url {
	// Get the filesystem path
	NSString *path = url.path;
	const char *fsName = path.fileSystemRepresentation;
	
	// Create the file stream.
	return opj_stream_create_default_file_stream(fsName, YES);
}

/**
 * Reads the component data from the OpenJPEG image structure, and creates a
 * CGImage from it. The bitmap data will be copied.
 */
+ (NSBitmapImageRep *) bitmapRepForOpenJPEGImage:(opj_image_t *) inImage {
	vImage_Error vErr;
	
	// Ensure the image is three components
	DDAssert(inImage->numcomps == 3, @"JPEG2000 images with not three components are not supported (got %i)", inImage->numcomps);
	
	// Get size of the image, and bits per sample
	CGSize imageSize = { .width = inImage->comps[0].w, .height = inImage->comps[0].h };
	
	NSUInteger bps = inImage->comps[0].prec;
//	NSUInteger bpp = inImage->comps[0].bpp;
	NSUInteger bpp = (bps * inImage->numcomps);
	
	// Allocate a buffer into which the planes are converted
	vImage_Buffer outBuf;
	vErr = vImageBuffer_Init(&outBuf, imageSize.height, imageSize.width,
							 (uint32_t) bpp, kvImageNoFlags);
	
	if(vErr != kvImageNoError) {
		DDLogError(@"vImageBuffer_Init failed: %zi", vErr);
		return nil;
	}
	
	// Convert the three separate planes to RGB888
	vImage_Buffer inPlane[8];
	
	for(NSUInteger i = 0; i < inImage->numcomps; i++) {
		// Get size information for the plane
		inPlane[i].width = inImage->comps[i].w;
		inPlane[i].height = inImage->comps[i].h;
		
		// Assume the row bytes are packed
		NSUInteger bytesPerPixel = inImage->comps[i].prec / 8;
		inPlane[i].rowBytes = (inPlane[i].width * bytesPerPixel);
		
		// Stick in the data pointer
		inPlane[i].data = inImage->comps[i].data;
		
//		DDLogVerbose(@"Buffer %zi: {%lu, %lu}, stride = %lu, ptr = %p", i, inPlane[i].width, inPlane[i].height, inPlane[i].rowBytes, inPlane[i].data);
		
		// Do the in-place conversion of the buffer
		if(bps == 8) {
			TSConvertOpenJPEGTo8BitInPlace(inPlane[i].data, inPlane[i].width, inPlane[i].height);
		} else if(bps == 16) {
			TSConvertOpenJPEGTo16BitInPlace(inPlane[i].data, inPlane[i].width, inPlane[i].height);
		}
	}
	
	// Handle conversion for three component images
	if(inImage->numcomps == 3) {
		// Use 8-bit per sample plane conversion
		if(bps == 8) {
			vErr = vImageConvert_Planar8toRGB888(&inPlane[0], &inPlane[1], &inPlane[2], &outBuf, kvImageNoFlags);
			
			if(vErr != kvImageNoError) {
				DDLogError(@"vImageConvert_Planar8toRGB888 failed: %zi", vErr);
				
				// Free some allocated objects
				free(outBuf.data);
				
				return nil;
			}
		}
		// Use 16-bit per sample plane conversion
		else if(bps == 16) {
			vErr = vImageConvert_Planar16UtoRGB16U(&inPlane[0], &inPlane[1], &inPlane[2], &outBuf, kvImageNoFlags);
			
			if(vErr != kvImageNoError) {
				DDLogError(@"vImageConvert_Planar16UtoRGB16U failed: %zi", vErr);
				
				// Free some allocated objects
				free(outBuf.data);
				
				return nil;
			}
		}
		// If the bits/sample isn't 8 or 16, it's not supported as of right now
		else {
			DDLogError(@"Unsupported bps: %zi", bps);
			
			// Free some allocated objects
			free(outBuf.data);
			
			return nil;
		}
	}
	
	
	// Create a bitmap representation for the output buffer
	NSBitmapImageRep *rep;
	
	rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
												  pixelsWide:imageSize.width
												  pixelsHigh:imageSize.height
											   bitsPerSample:bps
											 samplesPerPixel:inImage->numcomps
													hasAlpha:NO isPlanar:NO
											  colorSpaceName:NSDeviceRGBColorSpace
												 bytesPerRow:outBuf.rowBytes
												bitsPerPixel:(bps * inImage->numcomps)];
	
	// Copy bitmap data into it
	NSUInteger bitmapDataLen = (outBuf.rowBytes * outBuf.height);
	memcpy(rep.bitmapData, outBuf.data, bitmapDataLen);
	
	free(outBuf.data);
	
	// Check if the input image came with an ICC profile…
	if(inImage->icc_profile_len != 0) {
		// If so, load the ICC data…
		NSData *iccData = [NSData dataWithBytesNoCopy:inImage->icc_profile_buf
											   length:inImage->icc_profile_len
									  freeWhenDone:NO];
		NSColorSpace *space = [[NSColorSpace alloc] initWithICCProfileData:iccData];
		
		// …and re-tag the image with that colour space. This doesn't convert pixels.
		rep = [rep bitmapImageRepByRetaggingWithColorSpace:space];
	}
	
	// Done!
	return rep;
}

@end

/**
 * Converts an OpenJPEG 32-bit pixel buffer to 8-bit, in place.
 *
 * @note Makes the assumption that pixel data is tightly packed in memory, i.e.
 * the row stride is (width * bytesPerComponent)
 *
 * (Who the fuck thought it was a bright idea to allocate memory as if every
 * component were 32-bit, but then only shove an 8-bit value in it? Ugh.)
 */
static inline void TSConvertOpenJPEGTo8BitInPlace(uint32_t *inBuf, NSUInteger width, NSUInteger height) {
	uint8_t *outBuf = (uint8_t *) inBuf;
	
	// Calculate total number of pixels in multiples of four
	NSUInteger totalPixels = (width * height);
	
	NSUInteger fastPixels = totalPixels / 4;
	NSUInteger remainder = totalPixels - fastPixels;
	
	// Process four pixels at once (hopefully this gets vectorized)
	while(fastPixels-- != 0) {
		*outBuf++ = (uint8_t) *inBuf++;
		*outBuf++ = (uint8_t) *inBuf++;
		*outBuf++ = (uint8_t) *inBuf++;
		*outBuf++ = (uint8_t) *inBuf++;
	}
	
	// If any pixels remain, copy them individually
	if(remainder != 0) {
		for(NSUInteger i = 0; i > remainder; i++) {
			*outBuf++ = (uint8_t) *inBuf++;
		}
	}
}

/**
 * Converts an OpenJPEG 32-bit pixel buffer to 16-bit, in place.
 *
 * @note Makes the assumption that pixel data is tightly packed in memory, i.e.
 * the row stride is (width * bytesPerComponent)
 */
static inline void TSConvertOpenJPEGTo16BitInPlace(uint32_t *inBuf, NSUInteger width, NSUInteger height) {
	uint16_t *outBuf = (uint16_t *) inBuf;
	
	// Calculate total number of pixels in multiples of four
	NSUInteger totalPixels = (width * height);
	
	NSUInteger fastPixels = totalPixels / 4;
	NSUInteger remainder = totalPixels - fastPixels;
	
	// Process four pixels at once (hopefully this gets vectorized)
	while(fastPixels-- != 0) {
		*outBuf++ = (uint16_t) *inBuf++;
		*outBuf++ = (uint16_t) *inBuf++;
		*outBuf++ = (uint16_t) *inBuf++;
		*outBuf++ = (uint16_t) *inBuf++;
	}
	
	// If any pixels remain, copy them individually
	if(remainder != 0) {
		for(NSUInteger i = 0; i > remainder; i++) {
			*outBuf++ = (uint16_t) *inBuf++;
		}
	}
}