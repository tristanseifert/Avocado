//
//  TSThumbImageProxy+AvocadoApp.m
//  Avocado
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSThumbImageProxy+AvocadoApp.h"
#import "TSHumanModels.h"

@implementation TSThumbImageProxy (AvocadoApp)

/**
 * Creates a proxy image object, with its paramaeters drawn from the specified
 * library image object.
 */
+ (instancetype) proxyForImage:(TSLibraryImage *) image {
	TSThumbImageProxy *proxy = [TSThumbImageProxy new];
	
	// copy all relevant properties
	[image.managedObjectContext performBlockAndWait:^{
		proxy.size = image.imageSize;
		proxy.uuid = image.uuid;
		proxy.isRaw = (image.fileTypeValue == TSLibraryImageRaw);
		
		proxy.originalUrl = image.fileUrl;
	}];
	
	return proxy;
}

@end
