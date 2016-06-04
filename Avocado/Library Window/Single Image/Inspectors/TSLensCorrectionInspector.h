//
//  TSLensCorrectionInspector.h
//  Avocado
//
//  Created by Tristan Seifert on 20160604.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSDevelopInspector.h"

@class TSLFLens, TSLFCamera;
@interface TSLensCorrectionInspector : TSDevelopInspector

/// Whether lens corrections are enabled
@property (nonatomic) NSNumber *correctionsEnabled;

/// List of all suitable cameras
@property (nonatomic, readonly) NSArray<TSLFCamera *> *suitableCameras;
/// List of all suitable lenses
@property (nonatomic, readonly) NSArray<TSLFLens *> *suitableLenses;

@end
