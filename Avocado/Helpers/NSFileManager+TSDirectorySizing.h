//
//  NSFileManager+TSDirectorySizing.h
//  Legilus
//
//  Created by Tristan Seifert on 2015-11-24.
//  Copyright © 2015 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (TSDirectorySizing)

/**
 * Quickly calculates the size of the folder at the given URL.
 *
 * @param url URL of folder
 *
 * @return Size of folder, in bytes.
 */
- (unsigned long long) TSFileSizeForFolderAtUrl:(NSURL *) url;

/**
 * Quickly calculates the size of a file at the given URL.
 *
 * @param url URL of file
 *
 * @return Size of file, in bytes.
 */
- (unsigned long long) TSFileSizeForUrl:(NSURL *) url;

@end
