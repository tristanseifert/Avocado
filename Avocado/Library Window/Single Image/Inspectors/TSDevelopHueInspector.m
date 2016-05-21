//
//  TSDevelopHueInspector.m
//  Avocado
//
//  Created by Tristan Seifert on 20160518.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopHueInspector.h"

#import "TSHumanModels.h"

#import <MagicalRecord/MagicalRecord.h>

static void *TSActiveImageKVOCtx = &TSActiveImageKVOCtx;
static void *TSSettingsKVOCtx = &TSSettingsKVOCtx;

/// delay between invocations of change that must pass to re-render image
static const NSTimeInterval TSSettingsChangeDebounce = 0.66f;

@interface TSDevelopHueInspector ()

@end

@implementation TSDevelopHueInspector

- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopHueInspector" bundle:nil]) {
		self.title = NSLocalizedString(@"Hue, Saturation, Lightness", @"HSL inspector title");
		self.preferredContentSize = NSMakeSize(0, 235);
	}
	
	return self;
}

@end
