#import "TSLibraryImage.h"
#import "TSHumanModels.h"
#import "TSCoreDataStore.h"
#import "TSRawImage.h"
#import "NSDate+AvocadoUtils.h"
#import "TSImageIOHelper.h"

#import <ImageIO/ImageIO.h>
#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

#include <dlfcn.h>

// define the metadata keys
NSString* const TSLibraryImageMetadataKeyEXIF = @"TSLibraryImageMetadataEXIF";
NSString* const TSLibraryImageMetadataKeyCameraMaker = @"TSLibraryImageMetadataCameraMaker";
NSString* const TSLibraryImageMetadataKeyCameraModel = @"TSLibraryImageMetadataCameraModel";
NSString* const TSLibraryImageMetadataKeyLensMaker = @"TSLibraryImageMetadataLensMaker";
NSString* const TSLibraryImageMetadataKeyLensModel = @"TSLibraryImageMetadataLensModel";
NSString* const TSLibraryImageMetadataKeyLensSpecification = @"TSLibraryImageMetadataLensSpecification";
NSString* const TSLibraryImageMetadataKeyLensFocalLength = @"TSLibraryImageMetadataLensFocalLength";
NSString* const TSLibraryImageMetadataKeyExposureCompensation = @"TSLibraryImageMetadataExposureCompensation";
NSString* const TSLibraryImageMetadataKeyISO = @"TSLibraryImageMetadataISO";
NSString* const TSLibraryImageMetadataKeyShutter = @"TSLibraryImageMetadataShutter";
NSString* const TSLibraryImageMetadataKeyAperture = @"TSLibraryImageMetadataAperture";
NSString* const TSLibraryImageMetadataKeyAuthor = @"TSLibraryImageMetadataAuthor";
NSString* const TSLibraryImageMetadataKeyDescription = @"TSLibraryImageMetadataDescription";


/// default adjustments data; this is loaded once.
static NSDictionary<NSString *, NSDictionary<NSString *, NSNumber *> *> *TSDefaultAdjustments = nil;

/// context indicating that the date shot has changed
static void *TSLibraryImageDateShotKVOCtx = &TSLibraryImageDateShotKVOCtx;

@interface TSLibraryImage ()

/// cached LibRAW handle for this file. This may be released after a while.
@property (nonatomic, readonly) TSRawImage *libRawHandle;
/// cached ImageIO metadata
@property (nonatomic, readonly) NSDictionary *imageIOMetadata;

/// when set, any changes to the adjustments data are ignored
@property (nonatomic) BOOL ignoreAdjustmentChanges;

/// adjustments proxy
@property (nonatomic, strong) TSLibraryImageAdjustmentsProxy* adjustments;

- (void) commonInit;

- (void) addKVO;
- (void) removeKVO;

- (void) loadDefaultAdjustments;

@end

@implementation TSLibraryImage
@dynamic metadata, fileUrl, fileTypeValue, dayShotValue;
@synthesize libRawHandle = _libRawHandleCache;
@synthesize rotation = _imageRotationFromMetadata;
@synthesize imageIOMetadata = _imageIOMetadataCache;
@synthesize adjustments = _adjustments;
@synthesize ignoreAdjustmentChanges = _ignoreAdjustmentChanges;

#pragma mark Lifecycle
/**
 * Called when the object is first fetched from a managed object context.
 */
- (void) awakeFromFetch {
	[super awakeFromFetch];
	
	[self commonInit];
}

/**
 * Called when the object is first inserted into a managed object context.
 */
- (void) awakeFromInsert {
	[super awakeFromInsert];
	
	[self commonInit];
	
	// Set some default values
	[self setPrimitiveUuid:[NSUUID new].UUIDString];
	[self loadDefaultAdjustments];
	
	// Create lens correction data object
	TSLibraryImageCorrectionData *lensCorrect = [TSLibraryImageCorrectionData TSCreateEntityInContext:self.managedObjectContext];
	lensCorrect.enabled = @NO;
	
	self.correctionData = lensCorrect;
}

/**
 * Removes the KVO observers when the object turns into a fault.
 */
- (void) willTurnIntoFault {
	[super willTurnIntoFault];
	
	// remove KVO observers (fuck this shit)
	[self removeKVO];
	
	// clear caches
	_libRawHandleCache = nil;
	_imageRotationFromMetadata = TSLibraryImageRotationUnknown;
}

/**
 * Cleans up some more shit, like the fucking ridiculously broken KVO
 * observer things, on deallocation. This is a last ditch effort to prevent
 * the fucking moronically designed ObjC runtime from fucking itself when
 * a KVO observer is registered and we deallocate.
 */
- (void) dealloc {
	[self removeKVO];
}

/**
 * Common initialization that's performed when the object is fetched or
 * inserted from a store.
 */
- (void) commonInit {
	[self addKVO];
	
	// clear caches
	_imageRotationFromMetadata = TSLibraryImageRotationUnknown;
	
	// set up the adjustments proxy
	self.adjustments = [TSLibraryImageAdjustmentsProxy new];
	self.adjustments.image = self;
}

/**
 * Loads/creates the default adjustments data.
 *
 * @note This function does NOT do its own saving. The caller is responsible for
 * calling this either wrapped in an save block, or saving the managed object
 * context of this object directly afterward, such that the adjustments will
 * propagate correctly.
 */
- (void) loadDefaultAdjustments {
	// load the default adjustments… but only once
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSBundle *b;
		NSURL *url;
		
		// get the url of the plist
		b = [NSBundle mainBundle];
		url = [b URLForResource:@"TSLibraryImageDefaultAdjustments" withExtension:@"plist"];
		
		// then load it
		TSDefaultAdjustments = [NSDictionary dictionaryWithContentsOfURL:url];
	});
	
	// this is the date all adjustments will have
	NSDate *now = [NSDate new];
	
	// enumerate the adjustments dictionary
	[TSDefaultAdjustments enumerateKeysAndObjectsUsingBlock:^(NSString *adjustmentKey, NSDictionary<NSString *, NSNumber *> *values, BOOL *stop) {
		TSLibraryImageAdjustment *adj;
		
		// look up the actual key (they're the names of string consts)
		void *keyAddr = dlsym(RTLD_SELF, adjustmentKey.UTF8String);
		NSString *keyStr = *(NSString * __unsafe_unretained *) keyAddr;
		
		DDAssert([keyStr isKindOfClass:NSString.class] == YES, @"KeyAddr %p is incorrect, doesn't point to an NSString; this shouldn't happen", keyAddr);
		
		// create an object
		adj = [TSLibraryImageAdjustment TSCreateEntityInContext:self.managedObjectContext];
		DDAssert(adj != nil, @"Couldn't create adjustment object; this shouldn't happen");
		
		// set its key
		adj.property = keyStr;
		adj.dateAdded = now;
		
		// enumerate the values dict and set the appropriate key paths
		[values enumerateKeysAndObjectsUsingBlock:^(NSString *adjKey, NSNumber *adjValue, BOOL *stop) {
			if([adjValue isKindOfClass:NSNumber.class]) {
				[adj setValue:adjValue forKey:adjKey];
			
//				DDLogDebug(@"Setting adjustment %@: %@ = %@", keyStr, adjKey, adjValue);
			} else {
				DDLogWarn(@"Cannot set key %@ to %@ (type %@) on %@", adjKey, adjValue, NSStringFromClass(adjValue.class), keyStr);
			}
		}];
		
		// add to image
		[self addPvtAdjustmentsObject:adj];
	}];
}

#pragma mark KVO
/**
 * Adds KVO observers.
 */
- (void) addKVO {
	[self addObserver:self forKeyPath:@"dateShot" options:0
			  context:TSLibraryImageDateShotKVOCtx];
	
}

/**
 * Removes KVO observers.
 */
- (void) removeKVO {
	@try {
		[self removeObserver:self forKeyPath:@"dateShot"];
	} @catch (NSException* __unused) { }
}

/**
 * KVO handler
 */
- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	if(context == TSLibraryImageDateShotKVOCtx) {
		// set the "dayShot" to the date, sans time component
		self.dayShotValue = [self.dateShot timeIntervalSince1970WithoutTime];
	}
	// superclass handles other KVO
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Properties
/**
 * Converts the size, stored as a string, to an NSSize.
 */
- (NSSize) imageSize {
	return NSSizeFromString(self.pvtImageSize);
}

/**
 * Saves the size as a string.
 */
- (void) setImageSize:(NSSize) imageSize {
	self.pvtImageSize = NSStringFromSize(imageSize);
}

+ (NSSet *) keyPathsForValuesAffectingImageSize {
	return [NSSet setWithObject:@"pvtImageSize"];
}

/**
 * Returns the rotation angle.
 */
- (TSLibraryImageRotation) rotation {
	if(_imageRotationFromMetadata == TSLibraryImageRotationUnknown) {
		// if it's a RAW file, consult LibRaw
		if(self.fileTypeValue == TSLibraryImageRaw) {
			// no rotation
			if(self.libRawHandle.rotation == 0)
				_imageRotationFromMetadata = TSLibraryImageNoRotation;
			// 180° rotation
			else if(self.libRawHandle.rotation == 180)
				_imageRotationFromMetadata = TSLibraryImage180Degrees;
			// 90° counterclockwise rotation
			else if(self.libRawHandle.rotation == 90)
				_imageRotationFromMetadata = TSLibraryImage90DegreesCCW;
			// 90° clockwise rotation
			else if(self.libRawHandle.rotation == -90)
				_imageRotationFromMetadata = TSLibraryImage90DegreesCW;
		}
		// otherwise, query ImageIO
		else {
			// get the rotation key
			NSNumber *rotation = self.imageIOMetadata[TSImageMetadataOrientation];
			
			if(rotation.integerValue == 3) {
				_imageRotationFromMetadata = TSLibraryImage180Degrees;
			} else if(rotation.integerValue == 6) {
				_imageRotationFromMetadata = TSLibraryImage90DegreesCW;
			} else if(rotation.integerValue == 5 || rotation.integerValue == 8) {
				_imageRotationFromMetadata = TSLibraryImage90DegreesCCW;
			} else {
				// unknown (or no rotation)
				_imageRotationFromMetadata = TSLibraryImageNoRotation;
			}
			
//			DDLogVerbose(@"Determined rotation %lu for %@", rotation.integerValue, self.fileUrl);
		}
	}
	
	// return the cached rotation
	return _imageRotationFromMetadata;
}

+ (NSSet *) keyPathsForValuesAffectingRotation {
	return [NSSet setWithObjects:@"fileUrl", @"metadata", nil];
}

/**
 * Returns the rotated image size.
 */
- (NSSize) rotatedImageSize {
	// get the size
	NSSize pixelSize = self.imageSize;
	
	// if rotation is either 90° or -90°, flip the dimensions
	if(self.rotation == TSLibraryImage90DegreesCW || self.rotation == TSLibraryImage90DegreesCCW) {
		pixelSize = (NSSize) {
			.width = pixelSize.height,
			.height = pixelSize.width
		};
	}
	
	// done
	return pixelSize;
}

+ (NSSet *) keyPathsForValuesAffectingRotatedImageSize {
	return [NSSet setWithObjects:@"rotationAngle", @"imageSize", nil];
}

#pragma mark Caches
/**
 * Gets the LibRAW handle.
 */
- (TSRawImage *) libRawHandle {
	if(_libRawHandleCache == nil) {
		TSRawImage *raw = nil;
		NSError *err = nil;
		
		// load the image
		raw = [[TSRawImage alloc] initWithContentsOfUrl:self.fileUrl
												  error:&err];
		
		if(err) {
			DDLogError(@"Couldn't get RAW handle for %@: %@", self.fileUrl, err);
			return nil;
		}
		
		// otherwise, store the handle
		_libRawHandleCache = raw;
	}
	
	return _libRawHandleCache;
}

/**
 * Gets ImageIO data.
 */
- (NSDictionary *) imageIOMetadata {
	// read metadata from file, if needed
	if(_imageIOMetadataCache == nil) {
		_imageIOMetadataCache = [[TSImageIOHelper sharedInstance] metadataForImageAtUrl:self.fileUrl];
	}
	
	// return our internal cache
	return _imageIOMetadataCache;
}

@end
