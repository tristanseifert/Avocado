//
//  TSLFDatabase.h
//  Avocado
//
//  Created by Tristan Seifert on 20160525.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSLFLens.h"
#import "TSLFCamera.h"

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
- (TSLFCamera *) cameraForImage:(TSLibraryImage *) image;

/**
 * Attempts to find a lens object for the given image. If no suitable
 * lens can be found, nil is returned. If suitable lenses are found, an
 * array of lenses is returned.
 */
- (NSArray<TSLFLens *> *) lensForImage:(TSLibraryImage *) image;

@end
