//
//  TSColourControlsFilter.h
//  Avocado
//
//  Created by Tristan Seifert on 20160524.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreImageFilter.h"

@interface TSColourControlsFilter : TSCoreImageFilter

/// contrast adjustment; [-1, 1]
@property (nonatomic) CGFloat contrast;
/// saturation; [-1, 1]
@property (nonatomic) CGFloat saturation;
/// brightness; [0, 1]
@property (nonatomic) CGFloat brightness;

@end
