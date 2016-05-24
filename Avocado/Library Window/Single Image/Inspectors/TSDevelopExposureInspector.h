//
//  TSDevelopExposureInspector.h
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSDevelopInspector.h"

@interface TSDevelopExposureInspector : TSDevelopInspector

/// exposure adjustment, in EV
@property (nonatomic) NSNumber *exposureAdjustment;

/// contrast adjustment; [-1, 1]
@property (nonatomic) NSNumber *contrastAdjustment;
/// saturation adjustment; [-1, 1]
@property (nonatomic) NSNumber *saturationAdjustment;

@end
