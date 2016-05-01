//
//  TSRawImage.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSRawImage.h"

#import "libraw.h"

NSString *const TSRawImageErrorDomain = @"TSRawImageErrorDomain";
NSString *const TSRawImageErrorIsFatalKey = @"TSRawImageErrorIsFatal";

@interface TSRawImage ()

// redefine some properties as writeable
@property (nonatomic, readwrite) NSImage *thumbnail;

// internal properties
@property (nonatomic, assign) libraw_data_t *libRaw;
@property (nonatomic) NSURL *fileUrl;
@property (nonatomic) NSData *fileData;

// internal helpers
- (BOOL) loadFile:(NSURL *) url withError:(NSError **) outErr;

- (BOOL) unpackThumbs;
- (BOOL) unpackRaw;

- (void) convertEmbeddedThumbnail;

- (NSError *) errorFromCode:(int) code;

@end

@implementation TSRawImage

#pragma mark Initialization
/**
 * Initializes LibRaw, and loads the given image into it.
 */
- (instancetype) initWithContentsOfUrl:(NSURL *) url error:(NSError **) outErr {
	if(self = [super init]) {
		self.fileUrl = url;
		
		// init libraw
		self.libRaw = libraw_init(0);
		
		// load file and parse the thumbnails
		if([self loadFile:url withError:outErr] == NO) {
			return nil;
		}
		
		[self unpackThumbs];
		[self convertEmbeddedThumbnail];
	}
	
	return self;
}

/**
 * Releases LibRaw when the class is deallocated.
 */
- (void) dealloc {
	// first, releases resources back to the OS
	libraw_recycle(self.libRaw);
	
	// free the buffer of read data
	self.fileData = nil;
}

#pragma mark File Handling
/**
 * Loads the given RAW file.
 */
- (BOOL) loadFile:(NSURL *) url withError:(NSError **) outErr {
	int err = 0;
	NSError *nsErr = nil;
	
	// try to read the file
	self.fileData = [NSData dataWithContentsOfURL:url
										  options:NSDataReadingUncached
											error:&nsErr];
	
	if(self.fileData == nil) {
		DDLogError(@"Couldn't read RAW file from %@: %@", url, nsErr);
		if(outErr) *outErr = nsErr;
		
		return NO;
	}
	
	// open the file from the memory buffer
	void *data = (void *) self.fileData.bytes;
	size_t len = (size_t) self.fileData.length;
	
	
	if((err = libraw_open_buffer(self.libRaw, data, len)) != LIBRAW_SUCCESS) {
		nsErr = [self errorFromCode:err];
		
		DDLogError(@"Error opening RAW file: %i (%@)", err, nsErr);
		if(outErr) *outErr = nsErr;
		
		return NO;
	}
	
	// done
	return YES;
}

#pragma mark File Parsing
/**
 * Requests LibRaw to unpack the thumbnail images.
 */
- (BOOL) unpackThumbs {
	int err = 0;
	
	// unpack thumbnails
	if((err = libraw_unpack_thumb(self.libRaw)) != LIBRAW_SUCCESS) {
		NSError *nsErr = [self errorFromCode:err];
		
		if(LIBRAW_FATAL_ERROR(err)) {
			DDLogError(@"Couldn't unpack thumb: %@", nsErr);
			return NO;
		} else {
			DDLogWarn(@"Something happened trying to extract the thumb, but it was not a fatal error: %@", nsErr);
		}
	}

	// done
	return YES;
}

/**
 * Converts the thumbnail from whatever format is stored within the RAW image
 * to an NSImage.
 */
- (void) convertEmbeddedThumbnail {
	// pointer because this is way too fucking long to keep repeating
	enum LibRaw_thumbnail_formats format = self.libRaw->thumbnail.tformat;
	
	// create an NSData from the pointer to the thumb data w/o copying bytes
	NSData *data = [NSData dataWithBytesNoCopy:self.libRaw->thumbnail.thumb
										length:self.libRaw->thumbnail.tlength
								  freeWhenDone:NO];
	
	// we can only handle JPEG and bitmap thumbnails
	if(format == LIBRAW_THUMBNAIL_JPEG) {
		self.thumbnail = [[NSImage alloc] initWithData:data];
	} else if (format == LIBRAW_THUMBNAIL_BITMAP) {
		// TODO: Implement this maybe
	} else {
		// lol we're fucked, we should do something sophisticated here
		DDLogWarn(@"Unsupported thumbnail format: %u", format);
		
		self.thumbnail = nil;
	}
}

/**
 * Unpacks the RAW file and processes it.
 */
- (BOOL) unpackRaw {
	int err = 0;
	
	// unpack
	if((err = libraw_unpack(self.libRaw)) != LIBRAW_SUCCESS) {
		NSError *nsErr = [self errorFromCode:err];
		
		if(LIBRAW_FATAL_ERROR(err)) {
			DDLogError(@"Couldn't unpack file: %@", nsErr);
			return NO;
		} else {
			DDLogWarn(@"Something happened trying to unpack the file, but it was not a fatal error: %@", nsErr);
		}
	}
	
	// done
	return YES;
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
			NSLocalizedDescriptionKey: codeInfo,
			TSRawImageErrorIsFatalKey: @(LIBRAW_FATAL_ERROR(code))
			
		};
		err = [NSError errorWithDomain:NSPOSIXErrorDomain code:code
							  userInfo:info];
	}
	
	// return the created error
	return err;
}

#pragma mark Getters
/**
 * Returns the size (width, height) of the image.
 */
- (NSSize) getRawSize {
	return NSMakeSize(self.libRaw->sizes.iwidth,
					  self.libRaw->sizes.iheight);
}

/**
 * Returns a pointer to the image data.
 */
- (void *) getImageData {
//	self.libRaw.imgdata.rawdata
	return NULL;
}

/**
 * Returns the ISO speed, as a fraction.
 */
- (CGFloat) getExifISO {
	return self.libRaw->other.iso_speed;
}

/**
 * Returns the shutter speed, as a fraction.
 */
- (CGFloat) getExifShutter {
	return self.libRaw->other.shutter;
}

/**
 * Returns the aperture.
 */
- (CGFloat) getExifAperture {
	return self.libRaw->other.aperture;
}

/**
 * Returns the lens' name.
 */
- (NSString *) getExifLensName {
	return [NSString stringWithCString:self.libRaw->lens.Lens
							  encoding:NSUTF8StringEncoding];
}

/**
 * Returns the lens' make.
 */
- (NSString *) getExifLensMake {
	return [NSString stringWithCString:self.libRaw->lens.Lens
							  encoding:NSUTF8StringEncoding];
}

/**
 * Returns the focal length of the lens.
 */
- (NSUInteger) getExifLensFocalLength {
	return (NSUInteger) self.libRaw->other.focal_len;
}

/**
 * Returns the maker/manufacturer of the camera.
 */
- (NSString *) getExifCameraMake {
	return [NSString stringWithCString:self.libRaw->idata.make
							  encoding:NSUTF8StringEncoding];
}

/**
 * Returns the model of the camera.
 */
- (NSString *) getExifCameraModel {
	return [NSString stringWithCString:self.libRaw->idata.model
							  encoding:NSUTF8StringEncoding];
}

/**
 * Get the artist.
 */
- (NSString *) getMetaArtist {
	return [NSString stringWithCString:self.libRaw->other.artist
							  encoding:NSUTF8StringEncoding];
}

/**
 * Returns the "description" field of the image.
 */
- (NSString *) getMetaDescription {
	return [NSString stringWithCString:self.libRaw->other.desc
							  encoding:NSUTF8StringEncoding];
}

/**
 * Returns the timestamp embedded in the image.
 */
- (NSDate *) getMetaTimestamp {
	return [NSDate dateWithTimeIntervalSince1970:self.libRaw->other.timestamp];
}

/**
 * Returns the number in the 'series' of shot that this image is.
 */
- (NSUInteger) getMetaSeries {
	return self.libRaw->other.shot_order;
}

@end
