//
//  TSExposureAdjustmentFilter.h
//  Avocado
//
//  Created by Tristan Seifert on 20160519.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSCoreImageFilter.h"

@interface TSExposureAdjustmentFilter : TSCoreImageFilter

/// exposure adjustment, in EV
@property (nonatomic) CGFloat evAdjustment;

@end
