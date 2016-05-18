//
//  TSDevelopExposureInspector.m
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopExposureInspector.h"

@interface TSDevelopExposureInspector ()

@end

@implementation TSDevelopExposureInspector

- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopExposureInspector" bundle:nil]) {
		self.title = NSLocalizedString(@"Exposure", @"exposure inspector title");
		self.preferredContentSize = NSMakeSize(0, 238);
	}
	
	return self;
}

@end
