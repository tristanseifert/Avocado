#import "TSLibraryImage.h"
#import "TSRawImage.h"
#import "NSDate+AvocadoUtils.h"
#import "TSImageIOHelper.h"

#import <ImageIO/ImageIO.h>
#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

/// context indicating that the date shot has changed
static void *TSLibraryImageDateShotKVOCtx = &TSLibraryImageDateShotKVOCtx;
/// context indicating that the image adjustments dictionary has changed
static void *TSLibraryImageAdjustmentsKVOCtx = &TSLibraryImageAdjustmentsKVOCtx;

/// current adjustments version
const NSUInteger TSLibraryImageVersion = 0x00010000;

/// key for the adjustments dictionary
NSString * const TSLibraryImageAdjustmentKey = @"TSLibraryImageAdjustment";
/// key for the adjustments version in the adjustments dictionary
NSString * const TSLibraryImageVersionKey = @"TSLibraryImageVersion";

NSString * const TSAdjustmentKeyExposure = @"TSAdjustmentExposure";
NSString * const TSAdjustmentKeyExposureEV = @"TSAdjustmentExposureEV";

NSString  * _Nonnull const TSAdjustmentKeyDetail = @"TSAdjustmentDetail";

NSString * _Nonnull const TSAdjustmentKeyNoiseReductionLevel = @"TSAdjustmentNoiseReductionLevel";
NSString * _Nonnull const TSAdjustmentKeyNoiseReductionSharpness = @"TSAdjustmentNoiseReductionSharpness";

NSString * _Nonnull const TSAdjustmentKeySharpenLuminance = @"TSAdjustmentSharpenLuminance";
NSString * _Nonnull const TSAdjustmentKeySharpenRadius = @"TSAdjustmentSharpenRadius";
NSString * _Nonnull const TSAdjustmentKeySharpenIntensity = @"TSAdjustmentSharpenIntensity";
NSString * _Nonnull const TSAdjustmentKeySharpenMedianFilter = @"TSAdjustmentSharpenMedianFilter";

@interface TSLibraryImage ()

/// cached LibRAW handle for this file. This may be released after a while.
@property (nonatomic, readonly) TSRawImage *libRawHandle;
/// cached ImageIO metadata
@property (nonatomic, readonly) NSDictionary *imageIOMetadata;

/// when set, any changes to the adjustments data are ignored
@property (nonatomic) BOOL ignoreAdjustmentChanges;

- (void) commonInit;

- (void) addKVO;
- (void) removeKVO;

- (void) loadDefaultAdjustments;
- (void) decodeAdjustmentsData;
- (void) encodeAdjustmentsData;

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
	
	// set default values
	[self setPrimitiveUuid:[NSUUID new].UUIDString];
	[self loadDefaultAdjustments];
}

/**
 * Removes the KVO observers when the object turns into a fault.
 */
- (void) willTurnIntoFault {
	[super willTurnIntoFault];
	
	// encode the adjustments dictionary
	[self encodeAdjustmentsData];
	
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
}

/**
 * Loads/creates the default adjustments data.
 */
- (void) loadDefaultAdjustments {
	NSMutableDictionary *filter;
	
	// create adjusments dict
	NSMutableDictionary<NSString *, NSDictionary *> *adjustments = [NSMutableDictionary new];
	
	// create exposure adjustments
	filter = [NSMutableDictionary new];
	
	filter[TSAdjustmentKeyExposureEV] = @0.f;
	
	adjustments[TSAdjustmentKeyExposure] = [filter copy];
	
	// create noise reduction and sharpening adjustments
	filter = [NSMutableDictionary new];
	
	filter[TSAdjustmentKeyNoiseReductionLevel] = @0.02f;
	filter[TSAdjustmentKeyNoiseReductionSharpness] = @0.4f;
	
	
	filter[TSAdjustmentKeySharpenLuminance] = @0.4f;
	
	filter[TSAdjustmentKeySharpenRadius] = @2.5f;
	filter[TSAdjustmentKeySharpenIntensity] = @0.5f;
	
	filter[TSAdjustmentKeySharpenMedianFilter] = @NO;
	
	
	adjustments[TSAdjustmentKeyDetail] = [filter copy];
	
	
	// save
	self.adjustments = [adjustments copy];
}

/**
 * Uses a keyed unarchiver to decode previously saved adjustments data.
 */
- (void) decodeAdjustmentsData {
	// if there is no data to decode, exit
	if(self.pvtAdjustmentData == nil) {
		DDLogWarn(@"There is no adjustment data; this shouldn't happen.");
		return;
	}
	
	// decode existing data
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:self.pvtAdjustmentData];
	unarchiver.requiresSecureCoding = YES;
	
	// check version
	NSUInteger ver = [unarchiver decodeIntegerForKey:TSLibraryImageVersionKey];
	
	if(ver < TSLibraryImageVersion) {
		DDLogDebug(@"Upgrading adjustments for %p from 0x%08lx to 0x%08lx", self, ver, TSLibraryImageVersion);
	}
	
	// decode adjustments
	self.ignoreAdjustmentChanges = YES;

	self.adjustments = [unarchiver decodeObjectOfClass:[NSDictionary class] forKey:TSLibraryImageAdjustmentKey];
	
	self.ignoreAdjustmentChanges = NO;
	
	// finish
	[unarchiver finishDecoding];
}

/**
 * Uses a keyed archiver to encode the current adjustments data.
 */
- (void) encodeAdjustmentsData {
	NSMutableData *d = [NSMutableData new];
	
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:d];
	archiver.requiresSecureCoding = YES;
	
	// set the version and data
	[archiver encodeInteger:TSLibraryImageVersion
					 forKey:TSLibraryImageVersionKey];
	
	[archiver encodeObject:self.adjustments
					forKey:TSLibraryImageAdjustmentKey];
	
	// finish and store raw data
	[archiver finishEncoding];
	
	self.pvtAdjustmentData = d;
}

#pragma mark KVO
/**
 * Adds KVO observers.
 */
- (void) addKVO {
	[self addObserver:self forKeyPath:@"dateShot" options:0
			  context:TSLibraryImageDateShotKVOCtx];
//	[self addObserver:self forKeyPath:@"adjustments" options:0
//			  context:TSLibraryImageAdjustmentsKVOCtx];
	
}

/**
 * Removes KVO observers.
 */
- (void) removeKVO {
	@try {
		[self removeObserver:self forKeyPath:@"dateShot"];
	} @catch (NSException __unused *exception) { }
	
	@try {
		[self removeObserver:self forKeyPath:@"adjustments"];
	} @catch (NSException __unused *exception) { }
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
	// adjustments changed
	else if(context == TSLibraryImageAdjustmentsKVOCtx) {
		if(self.ignoreAdjustmentChanges == YES) return;
		
		DDLogVerbose(@"Adjustments data changed for %p\n%@", self, [NSThread callStackSymbols]);
		[self encodeAdjustmentsData];
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

/**
 * Returns adjustment data; if it doesn't exist, it tries to load it, and if
 * that fails, simply returns the defaults.
 */
- (NSDictionary<NSString *, NSDictionary<NSString *, id> *> *) adjustments {
	if(_adjustments == nil) {
		// try to load stored adjustments data
		[self decodeAdjustmentsData];
		
		if(_adjustments != nil) {
			return _adjustments;
		}
		
		// otherwise, load the defaults
		[self loadDefaultAdjustments];
	}
	
	// return the stored adjustment data
	return _adjustments;
}

/**
 * Sets the adjustment data; calling this firstly stores it, then updates
 * the internal data representation.
 */
- (void) setAdjustments:(NSDictionary<NSString *,NSDictionary<NSString *,id> *> *) adjustments {
	_adjustments = adjustments;
	
	// save
	if(self.ignoreAdjustmentChanges == NO) {
		DDLogVerbose(@"Adjustments data setter called for %p (thread %@)\n%@", self, [NSThread currentThread].name, [NSThread callStackSymbols]);
		
		[self encodeAdjustmentsData];
	}
}

+ (NSSet *) keyPathsForValuesAffectingAdjustments {
	return [NSSet setWithObject:@"pvtAdjustmentData"];
}

@end
