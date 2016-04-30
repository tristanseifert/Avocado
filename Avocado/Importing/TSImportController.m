//
//  TSImportController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSImportController.h"
#import "TSRawImage.h"
#import "TSHumanModels.h"

#import <MagicalRecord/MagicalRecord.h>

NSString *const TSImportingErrorDomain = @"TSImportingErrorDomain";

@interface TSImportController ()

- (BOOL) importRaw:(NSURL *) url withError:(NSError **) outErr;

- (NSURL *) copyFile:(NSURL *) file withError:(NSError **) outErr;

@end

@implementation TSImportController

/**
 * Imports the given file.
 */
- (BOOL) importFile:(NSURL *) url withError:(NSError **) err {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	
	// first, verify whether the file can be imported (it's an image)
	NSString *uti;
	[url getResourceValue:&uti forKey:NSURLTypeIdentifierKey error:nil];
	
	if([workspace type:uti conformsToType:@"public.image"]) {
		*err = [NSError errorWithDomain:TSImportingErrorDomain
								   code:TSImportingErrorNotAnImage
							   userInfo:nil];
		return NO;
	}
	
	// try to determine what type of image it is
	if([workspace type:uti conformsToType:@"public.camera-raw-image"]) {
		return [self importRaw:url withError:err];
	} else {
		
	}
	
	// we should never get here
	return NO;
}

#pragma mark
/**
 * Imports a RAW image at the given url.
 */
- (BOOL) importRaw:(NSURL *) url withError:(NSError **) outErr {
	NSError *err = nil;
	TSRawImage *raw = nil;
	
	NSDictionary *meta = nil;
	
	// try to create a RAW image
	raw = [[TSRawImage alloc] initWithContentsOfUrl:url error:&err];
	if(!raw || err) {
		DDLogError(@"Couldn't create RAW file: %@", err);
		*outErr = err;
	}
	
	// extract some metadata from it
	
	// copy it to the library folder
	NSURL *newUrl = [self copyFile:url withError:&err];
	
	if(newUrl == nil || err) {
		*outErr = err;
		return NO;
	}
	
	// save it
	[MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *ctx) {
		// create an image
		TSLibraryImage *image = [TSLibraryImage MR_createEntityInContext:ctx];
		
		// set some basic metadata
		image.fileTypeValue = TSLibraryImageRaw;
		image.fileUrl = newUrl;
		
		image.metadata = meta;
		
		image.dateImported = [NSDate new];
		image.dateModified = image.dateImported;
		
		image.dateShot = raw.timestamp;
	}];
	
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
	NSURL *photoDir = [[fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	photoDir = [photoDir URLByAppendingPathComponent:@"me.tseifert.Avocado" isDirectory:YES];
	photoDir = [photoDir URLByAppendingPathComponent:@"Photos" isDirectory:YES];
	
	// create the YYYY-MM-DD format directory
	NSDateFormatter *formatter = [NSDateFormatter new];
	formatter.dateFormat = @"yyyy-MM-dd";
	formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
	formatter.timeStyle = NSDateFormatterNoStyle;
	
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

@end
