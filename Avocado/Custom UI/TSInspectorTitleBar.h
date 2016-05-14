//
//  TSInspectorTitleBar.h
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSVibrantView.h"

@interface TSInspectorTitleBar : TSVibrantView

/// target for the click action
@property (nonatomic) id target;
/// selector to invoke when clicked
@property (nonatomic) SEL action;

@end
