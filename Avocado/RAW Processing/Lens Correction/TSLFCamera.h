//
//  TSLFCamera.h
//  Avocado
//
//	ObjC wrapper around the LensFun camera object.
//
//  Created by Tristan Seifert on 20160526.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSLFCamera : NSObject

- (instancetype) initWithCamera:(void *) camera;

@end
