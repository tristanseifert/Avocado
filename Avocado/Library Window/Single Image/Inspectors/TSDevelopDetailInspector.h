//
//  TSDevelopDetailInspector.h
//  Avocado
//
//  Created by Tristan Seifert on 20160518.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSDevelopInspector.h"

@interface TSDevelopDetailInspector : TSDevelopInspector

@property (nonatomic) NSNumber *nrLevel;
@property (nonatomic) NSNumber *nrSharpness;

@property (nonatomic) NSNumber *sharpenLuminance;
@property (nonatomic) NSNumber *sharpenRadius;
@property (nonatomic) NSNumber *sharpenIntensity;

@property (nonatomic) NSNumber *sharpenMedianFilter;

@end
