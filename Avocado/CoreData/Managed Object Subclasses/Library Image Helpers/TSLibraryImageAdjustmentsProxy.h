//
//  TSLibraryImageAdjustmentsProxy.h
//  Avocado
//
//	This proxy class implements KVC in such a way that it automagically
//	will fetch the adjustment object and return it.
//
//	Keys are the adjustment constants, as specified in TSLibraryImage.h.
//
//  Created by Tristan Seifert on 20160521.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TSLibraryImage;
@interface TSLibraryImageAdjustmentsProxy : NSObject

@property (nonatomic) TSLibraryImage *image;

@end
