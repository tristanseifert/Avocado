//
//  TSLFDatabase.mm
//  Avocado
//
//  Created by Tristan Seifert on 20160525.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLFDatabase.h"
#import "TSHumanModels.h"

#import "lensfun.h"

static TSLFDatabase *sharedDatabase = nil;

@interface TSLFDatabase ()

- (void) loadLFDatabase;

@property (nonatomic) lfDatabase *lensDb;

@end

@implementation TSLFDatabase

/**
 * Returns the shared instance of the database. This object
 * should be used for all lookups.
 */
+ (instancetype) sharedInstance {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedDatabase = [TSLFDatabase new];
	});
	
	return sharedDatabase;
}

#pragma mark Initialization
/**
 * Performs some initialization.
 */
- (instancetype) init {
	if(self = [super init]) {
		// create the DB object
		self.lensDb = new lfDatabase();
		
		// initialize it (loading the database files)
		[self loadLFDatabase];
	}
	
	return self;
}

/**
 * Initializes the internal LensFun database object, by loading
 * all of the database files in the LensFunDB bundle.
 */
- (void) loadLFDatabase {
	// locate the LensfunDB bundle
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSURL *dbBundleUrl = [mainBundle URLForResource:@"LensfunDB"
									  withExtension:@"bundle"];
	
	NSBundle *dbBundle = [NSBundle bundleWithURL:dbBundleUrl];
	
	// find the directory containing the database files
	NSURL *dbFilesUrl = dbBundle.resourceURL;
	
	// load all files in that directory
	NSString *path = dbFilesUrl.path;
	const char *fsRep = path.fileSystemRepresentation;
	
	BOOL success = self.lensDb->LoadDirectory(fsRep);
	
	if(success == NO) {
		DDLogError(@"Couldn't load lens database; lens correction won't work.");
	}
}

#pragma mark Searching
/**
 * Attempts to find a camera object for the given image. If no camera could be
 * found, nil is returned.
 */
- (void) cameraForImage:(TSLibraryImage *) image {
	
}

@end
