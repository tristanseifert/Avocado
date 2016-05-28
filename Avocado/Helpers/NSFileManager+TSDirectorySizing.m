//
//  NSFileManager+TSDirectorySizing.m
//  Avocado
//
//  Created by Tristan Seifert on 20160528.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "NSFileManager+TSDirectorySizing.h"

#import <Carbon/Carbon.h>

@interface NSFileManager (TSDirectorySizing_Private)

/**
 * Gets the size of a directory, given an FSRef.
 */
- (unsigned long long) TSFileSizeForFolder:(FSRef *) ref;

/**
 * Gets a Carbon FSRef from the given URL.
 *
 * @param url URL to a certain file or directory.
 *
 * @return An FSRef structure for the URL.
 */
- (FSRef) TSFSRefForUrl:(NSURL *) url;

@end

@implementation NSFileManager (TSDirectorySizing)

/**
 * Quickly calculates the size of the folder at the given URL.
 *
 * @param url URL of folder
 *
 * @return Size of folder, in bytes.
 */
- (unsigned long long) TSFileSizeForFolderAtUrl:(NSURL *) url {
	// get an fsref for the url
	FSRef ref = [self TSFSRefForUrl:url];
	
	return [self TSFileSizeForFolder:&ref];
}

/**
 * Quickly calculates the size of a file at the given URL.
 *
 * @param url URL of file
 *
 * @return Size of file, in bytes.
 */
- (unsigned long long) TSFileSizeForUrl:(NSURL *) url {
	NSError *err = nil;
	NSDictionary *attr = nil;
	
	// get attributes
	attr = [self attributesOfItemAtPath:url.path error:&err];
	
	if(err != nil) {
		DDLogError(@"Error retrieving attributes for %@: %@", url, err);
		return 0;
	}
	
	// get size
	return [attr[NSFileSize] unsignedLongLongValue];
}

#pragma mark Carbon File Manager Wrappers
// Needed to shut up the fucking compiler, since Carbon is basically depreciated…
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
/**
 * Gets the size of the directory at the given FSRef.
 */
- (unsigned long long) TSFileSizeForFolder:(FSRef *) ref {
	FSIterator thisDirEnum = NULL;
	unsigned long long totalSize = 0; // NSUInteger?
	
	// number of items to process in each batch
	const ItemCount maxItemsPerFetch = 256;
	
	// Iterate the directory contents, recursing as necessary
	if (FSOpenIterator(ref, kFSIterateFlat, &thisDirEnum) == noErr) {
		ItemCount actualFetched;
		FSRef fetchedRefs[maxItemsPerFetch];
		FSCatalogInfo fetchedInfos[maxItemsPerFetch];
		
		// start off with the initial fetch of items
		OSErr fsErr = FSGetCatalogInfoBulk(thisDirEnum,
										   maxItemsPerFetch, &actualFetched,
										   NULL, kFSCatInfoDataSizes |
										   kFSCatInfoNodeFlags | kFSCatInfoRsrcSizes, fetchedInfos,
										   fetchedRefs, NULL, NULL);
		
		// loop for as long as there are more items
		while((fsErr == noErr) || (fsErr == errFSNoMoreItems)) {
			ItemCount thisIndex;
			for (thisIndex = 0; thisIndex < actualFetched; thisIndex++) {
				// Recurse if it's a folder
				if (fetchedInfos[thisIndex].nodeFlags & kFSNodeIsDirectoryMask) {
					totalSize += [self TSFileSizeForFolder:&fetchedRefs[thisIndex]];
				} else {
					// add the size for this item (both resource and data forks)
					totalSize += fetchedInfos[thisIndex].dataLogicalSize;
					totalSize += fetchedInfos[thisIndex].rsrcLogicalSize;
				}
			}
			
			// if there are no more items, exit
			if (fsErr == errFSNoMoreItems) {
				break;
			} else {
				// get more items
				fsErr = FSGetCatalogInfoBulk(thisDirEnum,
											 maxItemsPerFetch, &actualFetched,
											 NULL, kFSCatInfoDataSizes |
											 kFSCatInfoNodeFlags | kFSCatInfoRsrcSizes, fetchedInfos,
											 fetchedRefs, NULL, NULL);
			}
		}
		
		// finish with the iterator
		FSCloseIterator(thisDirEnum);
	}
	return totalSize;
}

/**
 * Gets a Carbon FSRef from the given URL.
 */
- (FSRef) TSFSRefForUrl:(NSURL *) url {
	NSString *path = url.path;
	
	// actually create the fsref
	FSRef fsref;
	OSStatus result = FSPathMakeRef((UInt8 *) [path UTF8String], &fsref, NULL);
	
	// handle error
	if (result < 0) {
		DDLogError(@"Error creating FSRef (url= %@): %ui", url, result);
	}
	
	return fsref;
}
#pragma clang diagnostic pop

@end
