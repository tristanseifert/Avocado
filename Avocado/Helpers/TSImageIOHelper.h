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

/// EXIF dictionary
#define TSImageMetadataExifDictionary ((NSString *) kCGImagePropertyExifDictionary)
/// EXIF: original date/time captured (as NSDate)
#define TSImageMetadataExifDateTimeOriginal ((NSString *) kCGImagePropertyExifDateTimeOriginal)

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
