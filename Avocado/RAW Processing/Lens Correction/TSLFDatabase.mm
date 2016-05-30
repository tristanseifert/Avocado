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
 *
 * @note Assume that this method is invoked on the queue of the context to which
 * this image belongs.
 */
- (TSLFCamera *) cameraForImage:(TSLibraryImage *) image {
	// get some camera maker information
	NSString *maker = image.metadata[TSLibraryImageMetadataKeyCameraMaker];
	const char *makerCStr = [maker cStringUsingEncoding:NSASCIIStringEncoding];
	
	NSString *model = image.metadata[TSLibraryImageMetadataKeyCameraModel];
	const char *modelCStr = [model cStringUsingEncoding:NSASCIIStringEncoding];
	
	// try to find a camera
	const lfCamera** cameras = self.lensDb->FindCameras(makerCStr, modelCStr);
	
	// if the first entry is nil, we couldn't find a camera; that's bad.
	if(cameras[0] == NULL) {
		DDLogVerbose(@"Couldn't find camera for maker = %@, model = %@", maker, model);
		
		lf_free(cameras);
		return nil;
	} else {
		// otherwise, use the FIRST entry in the list.
		const lfCamera *camera = cameras[0];
		TSLFCamera *obj = [[TSLFCamera alloc] initWithCamera:(void *) camera];
		
		// clean up
		lf_free(cameras);
		return obj;
	}
}

/**
 * Attempts to find a lens object for the given image. If no suitable
 * lens can be found, nil is returned.
 *
 * @note Assume that this method is invoked on the queue of the context to which
 * this image belongs.
 */
- (NSArray<TSLFLens *> *) lensForImage:(TSLibraryImage *) image {
	// get lens maker and specification string
	NSString *maker = image.metadata[TSLibraryImageMetadataKeyCameraMaker];
	const char *makerCStr = [maker cStringUsingEncoding:NSASCIIStringEncoding];
	
	NSString *specification = image.metadata[TSLibraryImageMetadataKeyLensSpecification];
	const char *specCStr = [specification cStringUsingEncoding:NSASCIIStringEncoding];
	
	// get a camera if working
	TSLFCamera *cameraObj = [self cameraForImage:image];
	if(cameraObj == nil) {
		// no camera found
		return nil;
	}
	
	lfCamera *cam = (__bridge lfCamera *) [cameraObj valueForKey:@"camera"];
	
	// try to find the lens objects
	NSMutableArray<TSLFLens *> *arr = [NSMutableArray new];
	
	const lfLens **lenses = self.lensDb->FindLenses(cam, makerCStr, specCStr);
	
	// for each lens, create an object wrapper
	do {
		// get lens and make object, then add to object
		const lfLens *lens = lenses[0];
		
		TSLFLens *lensObj = [[TSLFLens alloc] initWithLens:(void *) lens];
		[arr addObject:lensObj];
		
		// go to next lens
		lenses++;
	} while(*lenses != NULL);
	
	// copy thing
	return [arr copy];
}

@end