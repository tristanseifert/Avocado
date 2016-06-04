//
//  TSImportController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSImportController.h"
#import "TSRawImage.h"
#import "TSImageIOHelper.h"
#import "TSGroupContainerHelper.h"

#import "TSThumbCache.h"

#import "TSHumanModels.h"
#import "TSCoreDataStore.h"

NSString *const TSFileImportedNotificationName = @"TSFileImportedNotification";
NSString *const TSFileImportedNotificationUrlKey = @"TSFileImportedNotificationUrl";
NSString *const TSFileImportedNotificationImageKey = @"TSFileImportedNotificationImage";
NSString *const TSImportingErrorDomain = @"TSImportingErrorDomain";

@interface TSImportController ()

- (BOOL) importRaw:(NSURL *) url withError:(NSError **) outErr;
- (BOOL) importOtherImage:(NSURL *) url withError:(NSError **) outErr;

- (NSURL *) copyFile:(NSURL *) file withError:(NSError **) outErr;

- (NSDictionary *) metadataDictWithImageIOMetadata:(NSDictionary *) meta;
- (NSDictionary *) metadataDictWithRawFile:(TSRawImage *) raw andImageIOData:(NSDictionary *) exif;

@end

@implementation TSImportController

/**
 * Instnatiates the class.
 */
- (instancetype) init {
	if(self = [super init]) {
		self.copyFiles = YES;
	}
	
	return self;
}

#pragma mark Importing
/**
 * Imports the given file.
 */
- (BOOL) importFile:(NSURL *) url withError:(NSError **) err {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	
	// First, verify whether the file can be imported (it's an image)
	NSString *uti;
	[url getResourceValue:&uti forKey:NSURLTypeIdentifierKey error:nil];
	
	if([workspace type:uti conformsToType:@"public.image"] == NO) {
		*err = [NSError errorWithDomain:TSImportingErrorDomain
								   code:TSImportingErrorNotAnImage
							   userInfo:nil];
		return NO;
	}
	
	// Try to determine what type of image it is
	if([workspace type:uti conformsToType:@"public.camera-raw-image"]) {
		return [self importRaw:url withError:err];
	} else {
		return [self importOtherImage:url withError:err];
	}
	
	// Should never get here…
	return NO;
}

#pragma mark
/**
 * Imports a RAW image at the given url.
 */
- (BOOL) importRaw:(NSURL *) url withError:(NSError **) outErr {
	NSError *err = nil;
	TSRawImage *raw = nil;
	
	NSURL *actualImageUrl = url;
	
	// Copy it to the library folder
	if(self.copyFiles) {
		actualImageUrl = [self copyFile:url withError:&err];
		
		if(actualImageUrl == nil || err) {
			*outErr = err;
			return NO;
		}
	}
	
	// Try to create a RAW image
	raw = [[TSRawImage alloc] initWithContentsOfUrl:actualImageUrl
											  error:&err];
	if(!raw || err) {
		DDLogError(@"Couldn't load RAW file from %@: %@", actualImageUrl, err);
		*outErr = err;
		return NO;
	}
	
	// Extract some metadata from the image
	NSDictionary *exif = [[TSImageIOHelper sharedInstance] metadataForImageAtUrl:actualImageUrl];
	
	// Save the new image
	[TSCoreDataStore saveWithBlockAndWait:^(NSManagedObjectContext *ctx) {
		// Create an image
		TSLibraryImage *image = [TSLibraryImage TSCreateEntityInContext:ctx];
		
		// Set some basic metadata
		image.fileTypeValue = TSLibraryImageRaw;
		image.fileUrl = actualImageUrl;
		
		image.metadata = [self metadataDictWithRawFile:raw andImageIOData:exif];
		
		image.dateImported = [NSDate new];
		image.dateModified = image.dateImported;
		
		image.dateShot = raw.timestamp;
		image.imageSize = raw.size;
		
		
		// Extract a few keys from the fixed-up EXIF dictionary dictionary
		NSDictionary *exifFixed = exif[TSImageMetadataExifDictionary];
		if(exifFixed != nil) {
			image.dateDigitized = exifFixed[TSImageMetadataExifDateTimeDigitized];
			
			if(image.dateDigitized == nil) {
				image.dateDigitized = image.dateImported;
			}
		}
		
		
		// Post notification
		NSDictionary *info = @{
			TSFileImportedNotificationUrlKey: actualImageUrl,
			TSFileImportedNotificationImageKey: image
		};
		[[NSNotificationCenter defaultCenter] postNotificationName:TSFileImportedNotificationName object:self userInfo:info];
		
		// Request a thumb be generated for this image
		[[TSThumbCache sharedInstance] warmCacheWithThumbForImage:image];
	} completion:nil];
	
	// Import has successed.
	return YES;
}

/**
 * Imports a system-parseable type of image.
 */
- (BOOL) importOtherImage:(NSURL *) url withError:(NSError **) outErr {
	NSError *err = nil;
	
	NSURL *actualImageUrl = url;
	
	// Copy it to the library folder
	if(self.copyFiles) {
		actualImageUrl = [self copyFile:url withError:&err];
		
		if(actualImageUrl == nil || err) {
			*outErr = err;
			return NO;
		}
	}
	
	// Extract some metadata from the image
	NSDictionary *exif = [[TSImageIOHelper sharedInstance] metadataForImageAtUrl:actualImageUrl];
	
	// Create a new image object and save it
	[TSCoreDataStore saveWithBlockAndWait:^(NSManagedObjectContext *ctx) {
		TSLibraryImage *image = [TSLibraryImage TSCreateEntityInContext:ctx];
		
		// Set some basic metadata
		image.fileTypeValue = TSLibraryImageCompressed;
		image.fileUrl = actualImageUrl;
		
		image.metadata = [self metadataDictWithImageIOMetadata:exif];
		
		image.dateImported = [NSDate new];
		image.dateModified = image.dateImported;
		
		image.imageSize = [[TSImageIOHelper sharedInstance] sizeOfImageAtUrl:actualImageUrl];
		
		
		// Extract a few keys from the fixed-up EXIF dictionary dictionary
		NSDictionary *exifFixed = exif[TSImageMetadataExifDictionary];
		if(exifFixed != nil) {
			image.dateShot = exifFixed[TSImageMetadataExifDateTimeOriginal];
			image.dateDigitized = exifFixed[TSImageMetadataExifDateTimeDigitized];
			
			if(image.dateShot == nil) image.dateShot = image.dateImported;
			if(image.dateDigitized == nil) image.dateDigitized = image.dateImported;
		}

		
		// Post notification
		NSDictionary *info = @{
		   TSFileImportedNotificationUrlKey: actualImageUrl,
		   TSFileImportedNotificationImageKey: image
		};
		[[NSNotificationCenter defaultCenter] postNotificationName:TSFileImportedNotificationName object:self userInfo:info];
		
		// Request a thumb be generated for this image
		[[TSThumbCache sharedInstance] warmCacheWithThumbForImage:image];
	} completion:nil];
	
	// the import has successed.
	return YES;
}

#pragma mark Helpers
/**
 * Copies the given file into the photo storage location, returning the url
 * of the new file.
 */
- (NSURL *) copyFile:(NSURL *) file withError:(NSError **) outErr {
	NSError *err = nil;
	NSDate *date = nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// read it from the url
	[file getResourceValue:&date forKey:NSURLContentModificationDateKey
					 error:&err];
	
	if(date == nil || err != nil) {
		DDLogError(@"Couldn't get modification date of %@: %@", file, err);
		*outErr = err;
		
		return nil;
	}
	
	// get the path to the photos directory
	NSURL *photoDir = [TSGroupContainerHelper sharedInstance].appSupport;
	photoDir = [photoDir URLByAppendingPathComponent:@"Photos" isDirectory:YES];
	
	// create the YYYY-MM-DD format directory
	NSDateFormatter *formatter = [NSDateFormatter new];
	formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
	formatter.dateFormat = @"yyyy-MM-dd";
	
	NSString *dirName = [formatter stringFromDate:date];
	
	photoDir = [photoDir URLByAppendingPathComponent:dirName isDirectory:YES];
	
	// create directory
	if([fm createDirectoryAtURL:photoDir withIntermediateDirectories:YES
					 attributes:nil error:&err] == NO) {
		DDLogError(@"Couldn't create directory (%@): %@", photoDir, err);
		*outErr = err;
		
		return nil;
	}
	
	// copy the file pls
	photoDir = [photoDir URLByAppendingPathComponent:file.lastPathComponent
										 isDirectory:NO];
	
	if([fm copyItemAtURL:file toURL:photoDir error:&err] == NO) {
		DDLogError(@"Couldn't copy file (src = %@, dst = %@): %@", file, photoDir, err);
		*outErr = err;
		
		return nil;
	}
	
	// we're done.
	return photoDir;
}

/**
 * Creates a saveable metadata dictionary for an image, given a dictionary of
 * ImageIO metadata. (This is usually used for non-RAW images.)
 */
- (NSDictionary *) metadataDictWithImageIOMetadata:(NSDictionary *) meta {
	NSMutableDictionary *info = [NSMutableDictionary new];
	NSDictionary *exif = meta[TSImageMetadataExifDictionary];
	NSDictionary *tiff = meta[TSImageMetadataTiffDictionary];
	
	// camera info
	info[TSLibraryImageMetadataKeyCameraMaker] = tiff[TSImageMetadataTiffCaptureDeviceMake];
	info[TSLibraryImageMetadataKeyCameraModel] = tiff[TSImageMetadataTiffCaptureDeviceModel];
	
	// lens info
	info[TSLibraryImageMetadataKeyLensMaker] = exif[TSImageMetadataExifLensMake];
	info[TSLibraryImageMetadataKeyLensModel] = exif[TSImageMetadataExifLensModel];
	info[TSLibraryImageMetadataKeyLensSpecification] = exif[TSImageMetadataExifLensSpec];
	info[TSLibraryImageMetadataKeyLensFocalLength] = exif[TSImageMetadataExifFocalLength];
	
	// shot info
	if([exif[TSImageMetadataExifISO] count] != 0) {
		info[TSLibraryImageMetadataKeyISO] = [exif[TSImageMetadataExifISO] firstObject];
	} else {
		info[TSLibraryImageMetadataKeyISO] = @(0);
	}
	
	info[TSLibraryImageMetadataKeyShutter] = exif[TSImageMetadataExifShutterSpeed];
	info[TSLibraryImageMetadataKeyAperture] = exif[TSImageMetadataExifAperture];
	info[TSLibraryImageMetadataKeyExposureCompensation] = exif[TSImageMetadataExifExposureCompensation];
	
	// miscellaneous metadata
	info[TSLibraryImageMetadataKeyAuthor] = exif[TSImageMetadataExifCameraOwner]; // could be kCGImagePropertyTIFFArtist?
	info[TSLibraryImageMetadataKeyDescription] = @""; // we have nothing good to put here
	
	// EXIF data
	info[TSLibraryImageMetadataKeyEXIF] = exif;
	
	return [info copy];
}

/**
 * Creates a saveable metadata dictionary, given a particular RAW file, and the
 * EXIF data provided by ImageIO.
 */
- (NSDictionary *) metadataDictWithRawFile:(TSRawImage *) raw andImageIOData:(NSDictionary *) meta {
	NSMutableDictionary *info = [NSMutableDictionary new];
	
	NSDictionary *exif = meta[TSImageMetadataExifDictionary];
	NSDictionary *tiff = meta[TSImageMetadataTiffDictionary];
	
	// camera info
	info[TSLibraryImageMetadataKeyCameraMaker] = tiff[TSImageMetadataTiffCaptureDeviceMake];
	info[TSLibraryImageMetadataKeyCameraModel] = tiff[TSImageMetadataTiffCaptureDeviceModel];
	
	// lens info
	info[TSLibraryImageMetadataKeyLensMaker] = raw.lensMake;
	info[TSLibraryImageMetadataKeyLensModel] = raw.lensName;
	info[TSLibraryImageMetadataKeyLensSpecification] = raw.lensName; // best guess we have here?
	info[TSLibraryImageMetadataKeyLensFocalLength] = @(raw.focalLength);
	
	// shot exposure info
	info[TSLibraryImageMetadataKeyISO] = @(raw.isoSpeed);
	info[TSLibraryImageMetadataKeyShutter] = @(raw.shutterSpeed);
	info[TSLibraryImageMetadataKeyAperture] = @(raw.aperture);
	
	// miscellaneous metadata
	info[TSLibraryImageMetadataKeyAuthor] = raw.artist;
	info[TSLibraryImageMetadataKeyDescription] = raw.imageDescription;
	
	// copy any EXIF data, if we have it
	info[TSLibraryImageMetadataKeyEXIF] = exif;
	
	return [info copy];
}

@end
