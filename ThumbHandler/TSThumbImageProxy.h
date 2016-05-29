//
//  TSThumbImageProxy.h
//  Avocado
//
//	A proxy object that contains enough information about an image (represented
//	by the `TSLibraryImage` class in the app) to generate a thumbnail.
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSThumbImageProxy : NSObject <NSSecureCoding>

/// Image UUID
@property (nonatomic) NSString *uuid;
/// full size of the image
@property (nonatomic) NSSize size;
/// URL of the original file on disk
@property (nonatomic) NSURL *originalUrl;

/// when set, the image is a raw file; if clear, ImageIO is used for thumb creation
@property (nonatomic) BOOL isRaw;

@end
