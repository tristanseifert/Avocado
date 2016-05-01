//
//  TSImportController.h
//  Avocado
//
//	Handles importing of single files; they are processed and added to the
//	library.
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const TSFileImportedNotificationName;
extern NSString *const TSFileImportedNotificationUrlKey;
extern NSString *const TSFileImportedNotificationImageKey;

extern NSString *const TSImportingErrorDomain;

typedef NS_ENUM(NSUInteger, TSImportingErrorCodes) {
	TSImportingErrorNotAnImage = 1,
};

@interface TSImportController : NSObject

- (BOOL) importFile:(NSURL *) url withError:(NSError **) err;

@property (nonatomic) BOOL copyFiles;

@end
