//
//  TSThumbImageProxy+AvocadoApp.h
//  Avocado
//
//	Adds a convenience initializer that allows a proxy image to be created from
//	a library image object.
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSThumbImageProxy.h"

@class TSLibraryImage;
@interface TSThumbImageProxy (AvocadoApp)

/**
 * Creates a proxy image object, with its paramaeters drawn from the specified
 * library image object.
 *
 * @note This turns the on-disk URL into a bookmark url for the sandboxed XPC
 * service.
 */
+ (instancetype) proxyForImage:(TSLibraryImage *) image;

@end
