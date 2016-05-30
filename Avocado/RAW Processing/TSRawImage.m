//
//  TSRawImage.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSRawImage.h"

#import "TSRawImageDataHelpers.h"
#import "libraw.h"

NSString *const TSRawImageErrorDomain = @"TSRawImageErrorDomain";
NSString *const TSRawImageErrorIsFatalKey = @"TSRawImageErrorIsFatal";

@interface TSRawImage ()

// internal properties
@property (nonatomic, assign) libraw_data_t *libRaw;
@property (nonatomic) NSURL *fileUrl;
@property (nonatomic) NSData *fileData;

// internal helpers
- (BOOL) loadFile:(NSURL *) url withError:(NSError **) outErr;

- (BOOL) unpackRaw;

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
		
		// load file
		if([self loadFile:url withError:outErr] == NO) {
			return nil;
		}
	}
	
	return self;
}

/**
 * Releases LibRaw when the class is deallocated.
 */
- (void) dealloc {
	// Releases resources back to the OS
	libraw_close(self.libRaw);
	
	// Then, free the buffer of read data
	self.fileData = nil;
}

/**
 * Clears the raw file for repeated processing.
 */
- (BOOL) recycle {
	NSError *err = nil;
	
	// recycle the struct
	libraw_recycle(self.libRaw);
	
	// re-open the file
	if([self loadFile:self.fileUrl withError:&err] == NO) {
		DDLogError(@"Error recycling file %@: %@", self, err);
		return NO;
	}
	
	return YES;
}

#pragma mark File Handling
/**
 * Loads the given RAW file.
 */
- (BOOL) loadFile:(NSURL *) url withError:(NSError **) outErr {
	int err = 0;
	NSError *nsErr = nil;
	
	// try to read the file (or map into memory, if safe)
	self.fileData = [NSData dataWithContentsOfURL:url
										  options:NSDataReadingMappedIfSafe
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
 * Unpacks Bayer data from the raw file
 */
- (BOOL) unpackRawData:(NSError **) outErr {
	int err = 0;
	
	// unpack raw data
	if((err = libraw_unpack(self.libRaw)) != LIBRAW_SUCCESS) {
		// get the error and put it into the output
		NSError *nsErr = [self errorFromCode:err];
		if(outErr) *outErr = nsErr;
		
		// parse the error pls
		if(LIBRAW_FATAL_ERROR(err)) {
			DDLogError(@"Couldn't unpack raw data: %@", nsErr);
			return NO;
		} else {
			DDLogWarn(@"Something happened trying to unpack raw data, but it was not a fatal error: %@", nsErr);
		}
	}
	
	// done
	return YES;
}

/**
 * Unpacks the RAW file and processes it. This really just copies the
 * raw pixel data into memory
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

#pragma mark Raw data copying
/**
 * Copies the raw data from the file into the four colour buffer given as
 * an input. This is usually in the single component Bayer format, which
 * must be processed before it can be displayed meaningfully, though some
 * RAW files may contain data in a different format.
 *
 * @param outBuffer A buffer at least (width * height) * 4 * 2 bytes in
 * length. Assume each row has (width * 8) bytes.
 */
- (void) copyRawDataToBuffer:(void *) outBuffer {
	// adjust black levels
	unsigned short cblack[4] = {0,0,0,0};
	unsigned short dmax = 0;
	
	// use the appropriate copying routine
	if(self.libRaw->idata.filters || self.libRaw->idata.colors == 1) { // bayer, one component
		TSRawCopyBayerData(self.libRaw, cblack, &dmax, outBuffer);
	} else {
		DDLogError(@"Got an unsupported RAW format: filters = 0x%08x, colours = %i", self.libRaw->idata.filters, self.libRaw->idata.colors);
		DDAssert(false, @"Unsupported RAW format provided: %@", self.fileUrl);
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
	return NSMakeSize(self.libRaw->sizes.width,
					  self.libRaw->sizes.height);
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
	return [NSString stringWithCString:self.libRaw->lens.LensMake
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

/**
 * Returns the number of degrees the image must be rotated by for output,
 * assuming that positive values rotate counter-clockwise.
 */
- (NSInteger) getImageRotation {
	if(self.libRaw->sizes.flip == 3) {
		// 180°
		return 180;
	} else if(self.libRaw->sizes.flip == 5) {
		// 90° CCW
		return 90;
	} else if(self.libRaw->sizes.flip == 6) {
		// 90° CW
		return -90;
	}
	
	// no rotation needed, or unknown flip value
	return 0;
}

/**
 * Returns an NSColorSpace object for the camera's embedded ICC profile.
 */
- (NSColorSpace *) getCameraColourProfile {
	NSData *icc;
	
	if(self.libRaw->color.profile != nil) {
		// create data
		icc = [NSData dataWithBytesNoCopy:self.libRaw->color.profile
								   length:self.libRaw->color.profile_length
							 freeWhenDone:NO];
		
		// create a color space instance
		return [[NSColorSpace alloc] initWithICCProfileData:icc];
	}
	
	// profile wasn't created or somehow broke
	return nil;
}

@end
