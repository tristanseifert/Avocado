//
//  TSRawImage.h
//  Avocado
//
//	Similar to NSImage, this class allows loading and manipulation of a raw
//	file.
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

extern NSString *const TSRawImageErrorDomain;

extern NSString *const TSRawImageErrorIsFatalKey;

@interface TSRawImage : NSObject

- (instancetype) initWithContentsOfUrl:(NSURL *) url error:(NSError **) outErr;


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
@property (nonatomic, readonly, getter=getMetaArtist) NSString *artist;
/// 'description' field
@property (nonatomic, readonly, getter=getMetaDescription) NSString *imageDescription;

/// timestamp
@property (nonatomic, readonly, getter=getMetaTimestamp) NSDate *timestamp;
/// series number
@property (nonatomic, readonly, getter=getMetaSeries) NSUInteger shotSeries;

/// thumbnail image
@property (nonatomic, readonly) NSImage *thumbnail;

/// size of the final image
@property (nonatomic, readonly, getter=getRawSize) NSSize size;

@end