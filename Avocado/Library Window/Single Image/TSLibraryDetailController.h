//
//  TSLibraryDetailController.h
//  Avocado
//
//	A view controller that shows a single image in the central area, with
//	adjustment controls on the right side of the view.
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSMainLibraryContentViewController.h"

@class TSLibraryImage;
@interface TSLibraryDetailController : NSSplitViewController <TSMainLibraryContentViewController>

@property (nonatomic) TSLibraryImage *image;

- (IBAction) returnToLightTable:(id) sender;

@end
