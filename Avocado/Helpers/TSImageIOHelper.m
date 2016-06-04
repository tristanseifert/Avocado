//
//  TSImageIOHelper.m
//  Avocado
//
//  Created by Tristan Seifert on 20160501.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSImageIOHelper.h"

#import <ImageIO/ImageIO.h>

static TSImageIOHelper *helper = nil;

@interface TSImageIOHelper ()

@property (nonatomic) NSDateFormatter *exifDateFormatter;

@end

@implementation TSImageIOHelper

/**
 * Initializes some data needed to do things.
 */
- (instancetype) init {
	if(self = [super init]) {
		self.exifDateFormatter = [NSDateFormatter new];
		self.exifDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
		self.exifDateFormatter.dateFormat = @"yyyy:MM:dd HH:mm:ss";
	}
	
	return self;
}

/**
 * Returns the shared instance.
 */
+ (instancetype) sharedInstance {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		helper = [TSImageIOHelper new];
	});
	
	return helper;
}

#pragma mark Sizing
/**
 * Returns the size of the image at the given url, or NSZeroSize if the size
 * could not be determined.
 */
- (NSSize) sizeOfImageAtUrl:(NSURL *) url {
	NSSize size = NSZeroSize;
	
	NSDictionary *props = nil;
	
	// create an image source (used to read properties)
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef) url, NULL);
	
	if(imageSource == NULL) {
		DDLogError(@"Couldn't create image source for %@", url);
		return NSZeroSize;
	}
	
	NSDictionary *options = @{
		(NSString *) kCGImageSourceShouldCache: @NO
	};
	
	props = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (CFDictionaryRef) options));
	
	if(props != nil) {
		NSNumber *width = props[(NSString *) kCGImagePropertyPixelWidth];
		NSNumber *height = props[(NSString *) kCGImagePropertyPixelHeight];
		
		// create the size struct
		size = (NSSize) {
			.width = width.floatValue,
			.height = height.floatValue
		};
	} else {
		DDLogWarn(@"Couldn't read image properties from %@", url);
	}
	
	// clean up and return the size we determined
	CFRelease(imageSource);
	
	return size;
}

/**
 * Extracts all available metadata from the given image.
 */
- (NSDictionary *) metadataForImageAtUrl:(NSURL *) url {
	NSDictionary *props = nil;
	
	// Create an image source (used to read properties)
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef) url, NULL);
	
	if(imageSource == NULL) {
		DDLogError(@"Couldn't create image source for %@", url);
		return nil;
	}
	
	NSDictionary *options = @{
		(NSString *) kCGImageSourceShouldCache: @NO
	};
	
	// Extract metadata
	props = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (CFDictionaryRef) options));
	
	// Convert some metadatas pls
	NSMutableDictionary *finessedProps = [props mutableCopy];
	
	// Do stuff to EXIF fields
	NSMutableDictionary *exifProps = finessedProps[TSImageMetadataExifDictionary];
	
	if(exifProps) {
		NSDate *date = nil;
		
		// Convert Original date/time captured to NSDate
		date = [self.exifDateFormatter dateFromString:exifProps[TSImageMetadataExifDateTimeOriginal]];
		exifProps[TSImageMetadataExifDateTimeOriginal] = date;
		
		// Convert date digitized date/time captured to NSDate
		date = [self.exifDateFormatter dateFromString:exifProps[TSImageMetadataExifDateTimeDigitized]];
		exifProps[TSImageMetadataExifDateTimeDigitized] = date;
	}
	
	finessedProps[TSImageMetadataExifDictionary] = [exifProps copy];
	
	// Clean up and return metadata
	CFRelease(imageSource);
	
	return [finessedProps copy];
}

@end
