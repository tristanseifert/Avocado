//
//  TSLibRawWrapper.m
//  Avocado
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibRawWrapper.h"

#import "libraw.h"

@interface TSLibRawWrapper ()

@property (nonatomic) LibRaw *libRaw;

@end

@implementation TSLibRawWrapper

/**
 * Initializes the library.
 */
- (instancetype) init {
	if(self = [super init]) {
		// init libraw
		self.libRaw = new LibRaw();
	}
	
	return self;
}

/**
 * Loads the given RAW file.
 */
- (BOOL) loadFile:(NSURL *) url {
	int err = 0;
	
	// open the file, pls
	NSString *string = url.path;
	
	if((err = self.libRaw->open_file(string.fileSystemRepresentation)) != 0) {
		DDLogError(@"Error opening RAW file: %i", err);
		return NO;
	}
	
	// unpack the thumbnail
	if((err = self.libRaw->unpack_thumb()) != 0) {
		DDLogWarn(@"Couldn't extract thumbnail: %i", err);
	}
	
	// done
	return YES;
}

/**
 * Unpacks the RAW file and processes it.
 */
- (BOOL) parseFile {
	int err = 0;
	
	// unpack
	if((err = self.libRaw->unpack()) != 0) {
		DDLogError(@"Couldn't unpack file: %i", err);
		return NO;
	}
	
	// done
	return YES;
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
- (NSString *) getExifArtist {
	return [NSString stringWithCString:self.libRaw->imgdata.other.artist
							  encoding:NSUTF8StringEncoding];
}

/**
 * Returns the "description" field of the image.
 */
- (NSString *) getExifDescription {
	return [NSString stringWithCString:self.libRaw->imgdata.other.desc
							  encoding:NSUTF8StringEncoding];
}

@end
