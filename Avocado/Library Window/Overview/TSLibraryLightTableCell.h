//
//  TSLibraryLightTableCell.h
//  Avocado
//
//	Custom cell subclass that draws the image's thumbnail asynchronously.
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <CNGridView/CNGridView.h>

@class TSLibraryImage;
@interface TSLibraryLightTableCell : CNGridViewItem

@property (nonatomic) TSLibraryImage* image;

@end
