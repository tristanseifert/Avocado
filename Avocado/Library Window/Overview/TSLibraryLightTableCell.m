//
//  TSLibraryLightTableCell.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryLightTableCell.h"

@interface TSLibraryLightTableCell ()

@end

@implementation TSLibraryLightTableCell

/**
 * Initializes the content of the light table cell, building the appropriate
 * layer tree.
 */
- (id) initWithLayout:(CNGridViewItemLayout *) layout reuseIdentifier:(NSString *) reuseIdentifier {
	if(self = [super initWithLayout:layout reuseIdentifier:reuseIdentifier]) {
		self.wantsLayer = YES;
	}
	
	return self;
}

/**
 * drawRect override that does nothing, as the content is drawn by layers.
 */
//- (void) drawRect:(NSRect) dirtyRect {
//	// do nothing
//}

@end
