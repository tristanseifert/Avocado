//
//  TSImportUIController.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSImportUIController.h"
#import "TSImportController.h"
#import "TSImportOpenPanelAccessory.h"

static void *TSImportQueueCountRemainingCtx = &TSImportQueueCountRemainingCtx;

NSString *const TSDirectoryImportCompletedNotificationName = @"TSDirectoryImportCompletedNotification";
NSString *const TSDirectoryImportCompletedNotificationUrlKey = @"TSDirectoryImportCompletedNotificationUrl";

@interface TSImportUIController ()

// re-define some properties as readwrite
@property (nonatomic, readwrite) NSProgress *importProgress;
// internal properties
@property (nonatomic) TSImportOpenPanelAccessory *accessory;
@property (nonatomic) NSOpenPanel *openPanel;

@property (nonatomic) TSImportController *importer;
@property (nonatomic) NSURL *lastImportedDirectory;
@property (nonatomic) NSOperationQueue *importQueue;

/// errors that may have occurred during importing
@property (nonatomic) NSMutableArray<NSError *> *importErrors;

- (void) importDirectory:(NSURL *) url;

@end

@implementation TSImportUIController

/**
 * Initializes the import controller.
 */
- (instancetype) init {
	if(self = [super init]) {
		// load accessory view
		self.accessory = [[TSImportOpenPanelAccessory alloc] initWithNibName:@"TSImportPanelAccessory" bundle:nil];
		
		// create the open panel
		self.openPanel = [NSOpenPanel new];
		
		self.openPanel.title = NSLocalizedString(@"Import Images", @"import panel  title");
		self.openPanel.prompt = NSLocalizedString(@"Import", @"import panel button title");
		
		self.openPanel.showsTagField = NO;
		self.openPanel.canChooseFiles = NO;
		self.openPanel.canChooseDirectories = YES;
		self.openPanel.allowsMultipleSelection = NO;
		
		self.openPanel.accessoryView = self.accessory.view;
		self.openPanel.accessoryViewDisclosed = YES;
		
		// create import controller
		self.importer = [TSImportController new];
		
		// create a dispatch queue on which import operations exist
		self.importQueue = [NSOperationQueue new];
		
		self.importQueue.maxConcurrentOperationCount = 1;
		self.importQueue.qualityOfService = NSQualityOfServiceUserInitiated;
		
		self.importQueue.name = [NSString stringWithFormat:@"Import Queue (UICtrlr = %p)", self];
		
		[self.importQueue addObserver:self forKeyPath:@"operationCount" options:0 context:TSImportQueueCountRemainingCtx];
	}
	
	return self;
}

/**
 * Presents the open panel as a sheet on the given window.
 */
- (void) presentAsSheetOnWindow:(NSWindow *) window {
	[self.openPanel beginSheetModalForWindow:window
						   completionHandler:^(NSInteger result) {
		if(result == NSFileHandlingPanelOKButton) {
			// set up the importer
			self.importer.copyFiles = self.accessory.shouldCopyImages;
			
			// import all images in the selected directory
			[self importDirectory:self.openPanel.URL];
		}
	}];
}

#pragma mark KVO/Queue Handling
/**
 * KVO handler; called when the count of operations changes.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	if(context == TSImportQueueCountRemainingCtx) {
		if(self.importQueue.operationCount == 0) {
			DDLogVerbose(@"Importing images in %@ complete", self.lastImportedDirectory);
			
			// post a notification
			NSDictionary *info = @{
				TSDirectoryImportCompletedNotificationUrlKey: self.lastImportedDirectory
			};
			
			NSNotificationCenter *c = [NSNotificationCenter defaultCenter];
			[c postNotificationName:TSDirectoryImportCompletedNotificationName
							 object:self
						   userInfo:info];
		}
	}
}

#pragma mark Importing
/**
 * Imports all images in the given directory.
 */
- (void) importDirectory:(NSURL *) url {
	NSDirectoryEnumerator *e = nil;
	NSError *err = nil;
	
	NSNumber *isDirectory = nil;
	NSString *uti = nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	
	NSMutableArray<NSURL *> *filesToImport = [NSMutableArray new];
	
	// save the directory to import
	DDLogVerbose(@"Importing directory %@", url);
	self.lastImportedDirectory = url;
	
	// set up an enumerator
	e = [fm enumeratorAtURL:url
 includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLTypeIdentifierKey]
					options:0
			   errorHandler:nil];
	
	// iterate through the directory to find all files
	while((url = [e nextObject])) {
		// check if it's a directory
		if([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&err]) {
			// it's a file.
			if(isDirectory.boolValue == NO) {
				// get the UTI
				if([url getResourceValue:&uti forKey:NSURLTypeIdentifierKey error:nil]) {
					// it MUST conform to public.image for us to do anything with it
					if([workspace type:uti conformsToType:@"public.image"]) {
						[filesToImport addObject:url];
					}
				} else {
					DDLogError(@"Error determining UTI for %@: %@", url, err);
				}
			}
		} else {
			DDLogError(@"Error determining directory state for %@: %@", url, err);
		}
	}
	
	// now that we know what files to import, go through each one and import
	self.importProgress = [NSProgress progressWithTotalUnitCount:filesToImport.count];
	self.importErrors = [NSMutableArray new];
	
	[filesToImport enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
		[self.importQueue addOperationWithBlock:^{
			NSError *err = nil;
			
			// attempt to do the import
			DDLogVerbose(@"Importing %@", url);
			
			if([self.importer importFile:url withError:&err] == NO) {
				[self.importErrors addObject:err];
			}
			
			// update progress
			self.importProgress.completedUnitCount++;
			
		}];
	}];
}

@end
