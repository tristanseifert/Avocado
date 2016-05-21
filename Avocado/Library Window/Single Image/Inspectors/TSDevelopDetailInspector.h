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

@property (nonatomic) CGFloat nrLevel;
@property (nonatomic) CGFloat nrSharpness;

@property (nonatomic) CGFloat sharpenLuminance;
@property (nonatomic) CGFloat sharpenRadius;
@property (nonatomic) CGFloat sharpenIntensity;

@property (nonatomic) BOOL sharpenMedianFilter;

@end
