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

/// highlights adjustment, in EV
@property (nonatomic) NSNumber *highlightsAdjustment;
/// shadows adjustment, in EV
@property (nonatomic) NSNumber *shadowsAdjustment;
/// whites adjustment, in EV
@property (nonatomic) NSNumber *whitesAdjustment;
/// blacks adjustment, in EV
@property (nonatomic) NSNumber *blacksAdjustment;

/// contrast adjustment; [-1, 1]
@property (nonatomic) NSNumber *contrastAdjustment;
/// saturation adjustment; [-1, 1]
@property (nonatomic) NSNumber *saturationAdjustment;

/// vibrance adjustment; [-1, 1]
@property (nonatomic) NSNumber *vibranceAdjustment;

@end
