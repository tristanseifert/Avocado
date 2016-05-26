//
//  TSLFDatabase.h
//  Avocado
//
//  Created by Tristan Seifert on 20160525.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TSLibraryImage;
@interface TSLFDatabase : NSObject

/**
 * Returns the shared instance of the database. This object
 * should be used for all lookups.
 */
+ (instancetype) sharedInstance;

/**
 * Attempts to find a camera object for the given image. If no camera could be
 * found, nil is returned.
 */
- (void) cameraForImage:(TSLibraryImage *) image;

@end
