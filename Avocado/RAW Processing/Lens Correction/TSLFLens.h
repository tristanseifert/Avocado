//
//  TSLFLens.h
//  Avocado
//
//	ObjC wrapper around the camera object.
//
//  Created by Tristan Seifert on 20160526.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Encoded non-localized lens make, saved as NSData.
extern NSString* const TSLFLensKeyMake;
/// Encoded non-localized lens model, saved as NSData.
extern NSString* const TSLFLensKeyModel;
/// Encoded crop factor, saved as NSNumber.
extern NSString* const TSLFLensKeyCropFactor;

@interface TSLFLens : NSObject

- (instancetype) initWithLens:(void *) lens;

/// Maker string
@property (nonatomic, readonly) NSString *maker;
/// Model string
@property (nonatomic, readonly) NSString *model;
/// Display name (combined from a variety of parameters)
@property (nonatomic, readonly) NSString *displayName;
/// Sorting score (may be zero)
@property (nonatomic, readonly) NSInteger sortingScore;

/// Minimum focal length
@property (nonatomic, readonly) CGFloat focalMin;
/// Maximum focal length
@property (nonatomic, readonly) CGFloat focalMax;
/// Minimum aperture value (ex ƒ/2.0)
@property (nonatomic, readonly) CGFloat apertureMin;
/// Maximum aperture value (ex ƒ/22)
@property (nonatomic, readonly) CGFloat apertureMax;

/// Archived data; can be used to find this lens again later.
@property (nonatomic, readonly) NSData *persistentData;

@end
