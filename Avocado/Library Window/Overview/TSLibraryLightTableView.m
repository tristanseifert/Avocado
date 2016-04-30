//
//  TSLibraryLightTableView.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLibraryLightTableView.h"
#import "TSLibraryLightTableCell.h"

@implementation TSLibraryLightTableView

/**
 * Returns the custom image browser cell.
 */
- (IKImageBrowserCell *) newCellForRepresentedItem:(id) anItem {
	return [TSLibraryLightTableCell new];
}

@end
