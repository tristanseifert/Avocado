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

/// Encoded non-localized camera make, saved as NSData.
extern NSString* const TSLFCameraKeyMake;
/// Encoded non-localized camera model, saved as NSData.
extern NSString* const TSLFCameraKeyModel;
/// Encoded crop factor, saved as NSNumber.
extern NSString* const TSLFCameraKeyCropFactor;

@interface TSLFCamera : NSObject

- (instancetype) initWithCamera:(void *) camera;

/// Maker string
@property (nonatomic, readonly) NSString *maker;
/// Model string
@property (nonatomic, readonly) NSString *model;

/// Crop factor of the sensor of this camera.
@property (nonatomic, readonly) CGFloat cropFactor;

/// Display name (combined from a variety of parameters)
@property (nonatomic, readonly) NSString *displayName;

/// Archived data; can be used to find this camera again later.
@property (nonatomic, readonly) NSData *persistentData;

@end
