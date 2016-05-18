//
//  TSDevelopDetailInspector.m
//  Avocado
//
//  Created by Tristan Seifert on 20160518.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSDevelopDetailInspector.h"

@interface TSDevelopDetailInspector ()

@end

@implementation TSDevelopDetailInspector

- (instancetype) init {
	if(self = [super initWithNibName:@"TSDevelopDetailInspector" bundle:nil]) {
		self.title = NSLocalizedString(@"Detail", @"detauk inspector title");
		self.preferredContentSize = NSMakeSize(0, 223);
	}
	
	return self;
}

@end
