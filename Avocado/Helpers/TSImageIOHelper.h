//
//  TSImageIOHelper.h
//  Avocado
//
//	Exposes various helper methods that abstract away some of the messiness
//	of ImageIO's plain C interface.
//
//  Created by Tristan Seifert on 20160501.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

/// General: Image orientation
#define TSImageMetadataOrientation ((NSString *) kCGImagePropertyOrientation)

/// TIFF dictionary
#define TSImageMetadataTiffDictionary ((NSString *) kCGImagePropertyTIFFDictionary)
/// TIFF: Capture device make
#define TSImageMetadataTiffCaptureDeviceMake ((NSString *) kCGImagePropertyTIFFMake)
/// TIFF: Capture device model
#define TSImageMetadataTiffCaptureDeviceModel ((NSString *) kCGImagePropertyTIFFModel)


/// EXIF dictionary
#define TSImageMetadataExifDictionary ((NSString *) kCGImagePropertyExifDictionary)
/// EXIF: original date/time captured (as NSDate)
#define TSImageMetadataExifDateTimeOriginal ((NSString *) kCGImagePropertyExifDateTimeOriginal)
/// EXIF: Gain control
#define TSImageMetadataExifGainControl ((NSString *) kCGImagePropertyExifGainControl)
/// EXIF: Focal length used to take the shot
#define TSImageMetadataExifFocalLength ((NSString *) kCGImagePropertyExifFocalLength)
/// EXIF: Lens make
#define TSImageMetadataExifLensMake ((NSString *) kCGImagePropertyExifLensMake)
/// EXIF: Lens model
#define TSImageMetadataExifLensModel ((NSString *) kCGImagePropertyExifLensModel)
/// EXIF: Lens specification (maker-specific string)
#define TSImageMetadataExifLensSpec ((NSString *) kCGImagePropertyExifLensSpecification)
/// EXIF: Exposure compensation
#define TSImageMetadataExifExposureCompensation ((NSString *) kCGImagePropertyExifExposureBiasValue)
/// EXIF: Shutter speed
#define TSImageMetadataExifShutterSpeed ((NSString *) kCGImagePropertyExifExposureTime)
/// EXIF: Aperture
#define TSImageMetadataExifAperture ((NSString *) kCGImagePropertyExifApertureValue)
/// EXIF: Shutter speed
#define TSImageMetadataExifISO ((NSString *) kCGImagePropertyExifISOSpeedRatings)
/// EXIF: Camera owner
#define TSImageMetadataExifCameraOwner ((NSString *) kCGImagePropertyExifCameraOwnerName)

@interface TSImageIOHelper : NSObject

+ (instancetype) sharedInstance;

/**
 * Returns the size of the image at the given url, or NSZeroSize if the size
 * could not be determined.
 */
- (NSSize) sizeOfImageAtUrl:(NSURL *) url;

/**
 * Extracts all available metadata from the given image.
 */
- (NSDictionary *) metadataForImageAtUrl:(NSURL *) url;

@end
