//
//  TSLibraryLightTableCell.h
//  Avocado
//
//	Custom cell subclass that draws the image's thumbnail asynchronously.
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Quartz/Quartz.h>

extern NSString* _Nonnull const TSLibraryLightTableInvalidateThumbsNotificationName;

@class TSLibraryImage;
@interface TSLibraryLightTableCell : NSCollectionViewItem

@property (nullable, strong) TSLibraryImage *representedObject;
@property (nonatomic) NSUInteger imageSequence;

- (void) forceRelayout;

@end
