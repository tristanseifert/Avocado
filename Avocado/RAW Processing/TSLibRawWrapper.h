//
//  TSLibRawWrapper.h
//  Avocado
//
//	An instance of this class can be created for each RAW file that needs to
//	be processed.
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSLibRawWrapper : NSObject

- (BOOL) loadFile:(NSURL *) url;
- (BOOL) parseFile;


/// iso speed
@property (nonatomic, readonly, getter=getExifISO) CGFloat isoSpeed;
/// shutter speed
@property (nonatomic, readonly, getter=getExifShutter) CGFloat shutterSpeed;
/// effective aperture
@property (nonatomic, readonly, getter=getExifAperture) CGFloat aperture;

/// lens name
@property (nonatomic, readonly, getter=getExifLensName) NSString *lensName;
/// lens make
@property (nonatomic, readonly, getter=getExifLensMake) NSString *lensMake;
/// lens focal length (35mm eq.)
@property (nonatomic, readonly, getter=getExifLensFocalLength) NSUInteger focalLength;

/// camera make
@property (nonatomic, readonly, getter=getExifCameraMake) NSString *cameraMake;
/// camera model
@property (nonatomic, readonly, getter=getExifCameraModel) NSString *cameraModel;

/// author
@property (nonatomic, readonly, getter=getExifArtist) NSString *artist;
/// 'description' field
@property (nonatomic, readonly, getter=getExifDescription) NSString *imageDescription;

/// size of the final image
@property (nonatomic, readonly, getter=getRawSize) NSSize size;

@end
