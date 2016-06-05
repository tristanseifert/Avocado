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

// Re-define some properties as readwrite
@property (nonatomic, readwrite) NSProgress *importProgress;
// Internal properties
@property (nonatomic) TSImportOpenPanelAccessory *accessory;
@property (nonatomic) NSOpenPanel *openPanel;

@property (nonatomic) TSImportController *importer;
@property (nonatomic) NSURL *lastImportedDirectory;
@property (nonatomic) NSOperationQueue *importQueue;

/// Errors that may have occurred during importing
@property (nonatomic) NSMutableArray<NSError *> *importErrors;

- (void) importDirectory:(NSURL *) url;

@end

@implementation TSImportUIController

/**
 * Initializes the import controller.
 */
- (instancetype) init {
	if(self = [super init]) {
		// Load accessory view
		self.accessory = [[TSImportOpenPanelAccessory alloc] initWithNibName:@"TSImportPanelAccessory" bundle:nil];
		
		// Create the open panel
		self.openPanel = [NSOpenPanel new];
		
		self.openPanel.title = NSLocalizedString(@"Import Images", @"import panel  title");
		self.openPanel.prompt = NSLocalizedString(@"Import", @"import panel button title");
		
		self.openPanel.showsTagField = NO;
		self.openPanel.canChooseFiles = NO;
		self.openPanel.canChooseDirectories = YES;
		self.openPanel.allowsMultipleSelection = NO;
		
		self.openPanel.accessoryView = self.accessory.view;
		self.openPanel.accessoryViewDisclosed = YES;
		
		// Create import controller
		self.importer = [TSImportController new];
		
		// Create a dispatch queue on which import operations exist
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
			// Set up the importer
			self.importer.copyFiles = self.accessory.shouldCopyImages;
			
			// Import all images in the selected directory
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
			DDLogInfo(@"Importing images in %@ complete", self.lastImportedDirectory);
			
			// Post a notification
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
	
	// Save the directory to import
	DDLogDebug(@"Importing images indirectory %@…", url);
	self.lastImportedDirectory = url;
	
	// Set up an enumerator
	e = [fm enumeratorAtURL:url
 includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLTypeIdentifierKey]
					options:0
			   errorHandler:nil];
	
	// Iterate through the directory to find all files
	while((url = [e nextObject])) {
		// Check if it's a directory
		if([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&err]) {
			// It's a file.
			if(isDirectory.boolValue == NO) {
				// Get the UTI
				if([url getResourceValue:&uti forKey:NSURLTypeIdentifierKey error:nil]) {
					// It MUST conform to public.image for us to do anything with it
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
	
	// Now that we know what files to import, go through each one and import
	self.importProgress = [NSProgress progressWithTotalUnitCount:filesToImport.count];
	self.importErrors = [NSMutableArray new];
	
	[filesToImport enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
		[self.importQueue addOperationWithBlock:^{
			NSError *err = nil;
			
			// Attempt to do the import
			DDLogDebug(@"Importing %@", url);
			
			if([self.importer importFile:url withError:&err] == NO) {
				[self.importErrors addObject:err];
			}
			
			// Update progress
			self.importProgress.completedUnitCount++;
			
		}];
	}];
}

@end
