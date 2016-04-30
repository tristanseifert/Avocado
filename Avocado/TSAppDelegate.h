//
//  AppDelegate.h
//  Avocado
//
//  Created by Tristan Seifert on 20160428.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TSMainLibraryWindowController;
@interface TSAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic) TSMainLibraryWindowController *mainWindow;

@end

