//
//  TSLibraryOverviewLightTableController.h
//  Avocado
//
//	Serves as a data source and delegate for the grid view on the light table
//	view.
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Quartz/Quartz.h>

@interface TSLibraryOverviewLightTableController : NSObject

- (instancetype) initWithGridView:(IKImageBrowserView *) view;

@end
