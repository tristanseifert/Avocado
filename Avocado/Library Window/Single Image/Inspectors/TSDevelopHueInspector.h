//
//  TSDevelopHueInspector.h
//  Avocado
//
//  Created by Tristan Seifert on 20160518.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSDevelopInspector.h"

@interface TSDevelopHueInspector : TSDevelopInspector

/// red adjustments
@property (nonatomic) NSMutableDictionary *redAdjustments;
/// orange adjustments
@property (nonatomic) NSMutableDictionary *orangeAdjustments;
/// yellow adjustments
@property (nonatomic) NSMutableDictionary *yellowAdjustments;
/// green adjustments
@property (nonatomic) NSMutableDictionary *greenAdjustments;
/// aqua adjustments
@property (nonatomic) NSMutableDictionary *aquaAdjustments;
/// blue adjustments
@property (nonatomic) NSMutableDictionary *blueAdjustments;
/// purple adjustments
@property (nonatomic) NSMutableDictionary *purpleAdjustments;
/// magenta adjustments
@property (nonatomic) NSMutableDictionary *magentaAdjustments;

/// index of the current tab
@property (nonatomic) NSInteger selectedTab;
/// tab view
@property (nonatomic) IBOutlet NSTabView *tabView;

@end

