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

// TODO: Find a better way to expose this
@interface TSLFCamera ()
@property (nonatomic) lfCamera *camera;
@end

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
	// Get some camera maker information
	NSString *maker = image.metadata[TSLibraryImageMetadataKeyCameraMaker];
	const char *makerCStr = [maker cStringUsingEncoding:NSASCIIStringEncoding];
	
	NSString *model = image.metadata[TSLibraryImageMetadataKeyCameraModel];
	const char *modelCStr = [model cStringUsingEncoding:NSASCIIStringEncoding];
	
	// Try to find a camera
	const lfCamera** cameras = self.lensDb->FindCameras(makerCStr, modelCStr);
	
	// If NULL is returned, no camera was found
	if(cameras == nil) {
		return nil;
	}
	
	// If the first entry is nil, we couldn't find a camera; that's bad.
	if(cameras[0] == nil) {
		DDLogVerbose(@"Couldn't find camera for maker = %@, model = %@", maker, model);
		
		lf_free(cameras);
		return nil;
	}
	// Otherwise, use the FIRST entry in the list.
	else {
		const lfCamera *camera = new lfCamera(*cameras[0]);
		TSLFCamera *obj = [[TSLFCamera alloc] initWithCamera:(void *) camera];
		
		// Clean up
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
- (NSArray<TSLFLens *> *) lensesForImage:(TSLibraryImage *) image withFlags:(TSLFLensSearchFlags) flags {
	__block CGFloat focalLength;
	__block const char *makerCStr, *specCStr;
	
	TSLFLens *lensObj;
	
	// Get some data from the image
	[image.managedObjectContext performBlockAndWait:^{
		NSString *maker = image.metadata[TSLibraryImageMetadataKeyCameraMaker];
		makerCStr = [maker cStringUsingEncoding:NSASCIIStringEncoding];
		
		NSString *specification = image.metadata[TSLibraryImageMetadataKeyLensSpecification];
		specCStr = [specification cStringUsingEncoding:NSASCIIStringEncoding];
		
		focalLength = [image.metadata[TSLibraryImageMetadataKeyLensFocalLength] floatValue];
	}];
	
	// Get some flags that specify additional checks to do
	BOOL checkFocalLength = ((flags & kTSLFLensSearchIgnoreFocalLength) == 0);
	
	// Get a camera if working
	TSLFCamera *cameraObj = [self cameraForImage:image];
	if(cameraObj == nil) {
		// No camera found
		return nil;
	}
	
	lfCamera *cam = cameraObj.camera;
	
	// Try to find the lens objects
	NSMutableArray<TSLFLens *> *arr = [NSMutableArray new];
	
	const lfLens **lenses = self.lensDb->FindLenses(cam, makerCStr, specCStr, LF_SEARCH_LOOSE);
	
	// For each lens, create an object wrapper
	do {
		// Perform the focal length check
		if(checkFocalLength) {
			// Focal length must be MinFocal ≤ actualFocalLength ≤ MaxFocal
			if(focalLength < lenses[0]->MinFocal || focalLength > lenses[0]->MaxFocal) {
				goto nextLens;
			}
		}
		
		// Get lens and make object, then add to the array
		lensObj = [[TSLFLens alloc] initWithLens:(void *) new lfLens(*lenses[0])];
		[arr addObject:lensObj];
		
		// Go to next lens
	nextLens: ;
		lenses++;
	} while(*lenses != NULL);
	
	// Copy array to return a non-mutable class
	return [arr copy];
}

#pragma mark Helpers
/**
 * Searches a LensFun-foramtted "localized string" for the given locale; if no
 * string for that locale cane be found, the unlocalized string is returned.
 */
+ (NSString *) stringForLocale:(NSLocale *) locale inLFString:(char *) lfString {
	// Get the two-chracter language code
	NSString *langCodeNSStr = [locale objectForKey:NSLocaleLanguageCode];
	const char *langCode = langCodeNSStr.UTF8String;
	
	// Ensure input string is non-nill
	if (!lfString) {
		return nil;
	}
	
	// Default string
	const char *def = lfString;
	
	// Find the corresponding string
	const char *cur = strchr(lfString, 0) + 1;
	while (*cur) {
		// Go to the next string
		const char *next = strchr(cur, 0) + 1;
		
		// Do the language codes match?
		if (!strcmp (cur, langCode)) {
			def = next;
			break;
		}
		
		// Found the English string; that's the default string to output
		if (!strcmp (cur, "en")) {
			def = next;
		}
		
		// Find the next string
		if (*(cur = next)) {
			cur = strchr(cur, 0) + 1;
		}
	}
	
	// Done; return the correct string.
	NSString *str = [NSString stringWithUTF8String:def];
	return str;
}

#pragma mark Finding Specific Objects
/**
 *  Finds a previously found camera, given a data blob generated by its
 *	`persistentData` method.
 *
 *  @param data Persistent data (as produced by NSKeyedArchiver)
 *
 *  @return A camera object, or nil if one could not be found.
 */
- (TSLFCamera *) findCameraWithPersistentData:(NSData *) data {
	// Unarchive the data
	NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	archiver.requiresSecureCoding = YES;
	
	NSData *make = [archiver decodeObjectOfClass:[NSData class] forKey:TSLFCameraKeyMake];
	NSData *model = [archiver decodeObjectOfClass:[NSData class] forKey:TSLFCameraKeyModel];
//	CGFloat cropFactor = [archiver decodeDoubleForKey:TSLFCameraKeyCropFactor];
	
	[archiver finishDecoding];
	
	// Set up a database query
	const char *makeStr = (const char *) make.bytes;
	const char *modelStr = (const char *) model.bytes;
	
	// Query the database
	const lfCamera** cameras = self.lensDb->FindCameras(makeStr, modelStr);
	
	// If NULL is returned, no camera was found
	if(cameras == nil || cameras[0] == nil) {
		DDLogWarn(@"Couldn't find camera for maker = %s, model = %s; archived data = %@", makeStr, modelStr, data);
		
		if(cameras[0] == nil) {
			lf_free(cameras);
		}
		
		return nil;
	}
	// Otherwise, use the FIRST entry in the list.
	else {
		const lfCamera *camera = new lfCamera(*cameras[0]);
		TSLFCamera *obj = [[TSLFCamera alloc] initWithCamera:(void *) camera];
		
		// Clean up
		lf_free(cameras);
		return obj;
	}
}

/**
 *  Finds a previously found lens, given the data blob generated by its
 *	`persistentData` method.
 *
 *  @param data Persistent data (as produced by NSKeyedArchiver)
 *	@param camera Camera object that was previously decoded
 *
 *  @return A lens object, or nil if one could not be found.
 */
- (TSLFLens *) findLensWithPersistentData:(NSData *) data andCamera:(TSLFCamera *) camera {
	// Unarchive the data
	NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	archiver.requiresSecureCoding = YES;
	
	NSData *make = [archiver decodeObjectOfClass:[NSData class] forKey:TSLFLensKeyMake];
	NSData *model = [archiver decodeObjectOfClass:[NSData class] forKey:TSLFLensKeyModel];
	CGFloat cropFactor = [archiver decodeDoubleForKey:TSLFLensKeyCropFactor];
	
	[archiver finishDecoding];
	
	// Set up a database query
	const char *makeStr = (const char *) make.bytes;
	const char *modelStr = (const char *) model.bytes;
	lfCamera *cam = camera.camera;
	
	// Run the query
	const lfLens **lenses = self.lensDb->FindLenses(cam, makeStr, modelStr);
	
	// If nil was returned, no matching lenses are found.
	if(lenses == nil || lenses[0] == nil) {
		DDLogWarn(@"Couldn't find lens for maker = %s, model = %s; archived data = %@, camera = %@", makeStr, modelStr, data, camera);
		
		if(lenses[0] == nil) {
			lf_free(lenses);
		}
		
		return nil;
	}
	// Otherwise, find the lens with the matching crop factor
	else {
		do {
			// Does the crop factor match?
			if(lenses[0]->CropFactor == cropFactor) {
				// Create the object wrapper, if it does match.
				const lfLens *lens = new lfLens(*lenses[0]);
				TSLFLens *lensObj = [[TSLFLens alloc] initWithLens:(void *) lens];
				
				// Clean up
				lf_free(lenses);
				
				return lensObj;
			}
			
			// Go to next lens
			lenses++;
		} while(*lenses != NULL);
	}
	
	// No suitable lens was found… wat.
	DDLogWarn(@"Couldn't find lens for maker = %s, model = %s, crop = %f; archived data = %@, camera = %@; however, FindLenses returned data (this should never happen)", makeStr, modelStr, cropFactor, data, camera);
	return nil;
}

@end
