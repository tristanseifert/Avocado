//
//  TSImportUIController.h
//  Avocado
//
//	Handles displaying of the import dialog (a modified `NSOpenPanel`) and
//	accessory views that need to be displayed. It also contains logic to
//	import an entire directory of files.
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const TSDirectoryImportCompletedNotificationName;
extern NSString *const TSDirectoryImportCompletedNotificationUrlKey;

@interface TSImportUIController : NSObject

- (void) presentAsSheetOnWindow:(NSWindow *) window;

@property (nonatomic, readonly) NSProgress *importProgress;

@end
