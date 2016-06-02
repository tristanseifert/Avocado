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

/// Maker string
@property (nonatomic, readonly) NSString *maker;
/// Model string
@property (nonatomic, readonly) NSString *model;

@end
