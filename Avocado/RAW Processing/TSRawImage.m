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
@property (nonatomic) LibRaw *libRaw;

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
		// init libraw
		self.libRaw = new LibRaw();
		
		// load file and parse the thumbnails
		[self loadFile:url withError:outErr];
		
		[self unpackThumbs];
	}
	
	return self;
}

/**
 * Releases LibRaw when the class is deallocated.
 */
- (void) dealloc {
	// first, releases resources back to the OS
	self.libRaw->recycle();
	// then actually frees the memory occupied by the LibRaw instance
	delete self.libRaw;
}

#pragma mark File Handling
/**
 * Loads the given RAW file.
 */
- (BOOL) loadFile:(NSURL *) url withError:(NSError **) outErr {
	int err = 0;
	
	// open the file, pls
	NSString *string = url.path;
	
	if((err = self.libRaw->open_file(string.fileSystemRepresentation)) != 0) {
		DDLogError(@"Error opening RAW file: %i", err);
		if(outErr) *outErr = [self errorFromCode:err];
		
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
	if((err = self.libRaw->unpack_thumb()) != 0) {
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
	libraw_thumbnail_t *thumb = &self.libRaw->imgdata.thumbnail;
	
	enum LibRaw_thumbnail_formats format = thumb->tformat;
	
	// create an NSData from the pointer
	NSData *data = [NSData dataWithBytesNoCopy:thumb->thumb
										length:thumb->tlength];
	
	// we can only handle JPEG and bitmap thumbnails
	if(format == LIBRAW_THUMBNAIL_JPEG) {
		self.thumbnail = [[NSImage alloc] initWithData:data];
	} else if (format == LIBRAW_THUMBNAIL_BITMAP) {
		// TODO: Implement this
	} else {
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
	if((err = self.libRaw->unpack()) != 0) {
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
		codeInfo = [NSString stringWithCString:LibRaw::strerror(code)
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
	return NSMakeSize(self.libRaw->imgdata.sizes.iwidth,
					  self.libRaw->imgdata.sizes.iheight);
}

/**
 * Returns a pointer to the image data.
 */
- (void *) getImageData {
//	self.libRaw->imgdata.rawdata
	return NULL;
}

/**
 * Returns the ISO speed, as a fraction.
 */
- (CGFloat) getExifISO {
	return self.libRaw->imgdata.other.iso_speed;
}

/**
 * Returns the shutter speed, as a fraction.
 */
- (CGFloat) getExifShutter {
	return self.libRaw->imgdata.other.shutter;
}

/**
 * Returns the aperture.
 */
- (CGFloat) getExifAperture {
	return self.libRaw->imgdata.other.aperture;
}

/**
 * Returns the lens' name.
 */
- (NSString *) getExifLensName {
	return [NSString stringWithCString:self.libRaw->imgdata.lens.Lens
							  encoding:NSUTF8StringEncoding];
}

/**
 * Returns the lens' make.
 */
- (NSString *) getExifLensMake {
	return [NSString stringWithCString:self.libRaw->imgdata.lens.Lens
							  encoding:NSUTF8StringEncoding];
}

/**
 * Returns the focal length of the lens.
 */
- (NSUInteger) getExifLensFocalLength {
	return (NSUInteger) self.libRaw->imgdata.other.focal_len;
}

/**
 * Returns the maker/manufacturer of the camera.
 */
- (NSString *) getExifCameraMake {
	return [NSString stringWithCString:self.libRaw->imgdata.idata.make
							  encoding:NSUTF8StringEncoding];
}

/**
 * Returns the model of the camera.
 */
- (NSString *) getExifCameraModel {
	return [NSString stringWithCString:self.libRaw->imgdata.idata.model
							  encoding:NSUTF8StringEncoding];
}

/**
 * Get the artist.
 */
- (NSString *) getMetaArtist {
	return [NSString stringWithCString:self.libRaw->imgdata.other.artist
							  encoding:NSUTF8StringEncoding];
}

/**
 * Returns the "description" field of the image.
 */
- (NSString *) getMetaDescription {
	return [NSString stringWithCString:self.libRaw->imgdata.other.desc
							  encoding:NSUTF8StringEncoding];
}

/**
 * Returns the timestamp embedded in the image.
 */
- (NSDate *) getMetaTimestamp {
	return [NSDate dateWithTimeIntervalSince1970:self.libRaw->imgdata.other.timestamp];
}

/**
 * Returns the number in the 'series' of shot that this image is.
 */
- (NSUInteger) getMetaSeries {
	return self.libRaw->imgdata.other.shot_order;
}

@end
