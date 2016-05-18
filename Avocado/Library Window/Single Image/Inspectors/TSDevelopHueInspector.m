//
//  TSDevelopHueInspector.m
//  Avocado
//
//  Created by Tristan Seifert on 20160518.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopHueInspector.h"

@interface TSDevelopHueInspector ()

@end

@implementation TSDevelopHueInspector

- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopHueInspector" bundle:nil]) {
		self.title = NSLocalizedString(@"Hue, Saturation, Lightness", @"exposure inspector title");
		self.preferredContentSize = NSMakeSize(0, 235);
	}
	
	return self;
}

@end
