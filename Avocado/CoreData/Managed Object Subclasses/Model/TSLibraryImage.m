#import "TSLibraryImage.h"
#import "TSRawImage.h"
#import "NSDate+AvocadoUtils.h"
#import "TSImageIOHelper.h"

#import <ImageIO/ImageIO.h>
#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

/// current adjustments version
const NSUInteger TSLibraryImageVersion = 0x00010000;

/// key for the adjustments dictionary
NSString * const TSLibraryImageAdjustmentKey = @"TSLibraryImageAdjustment";
/// key for the adjustments version in the adjustments dictionary
NSString * const TSLibraryImageVersionKey = @"TSLibraryImageVersion";

NSString * const TSAdjustmentKeyExposure = @"TSAdjustmentExposure";
NSString * const TSAdjustmentKeyExposureEV = @"TSAdjustmentExposureEV";

NSString  * _Nonnull const TSAdjustmentKeyNoiseReduction = @"TSAdjustmentNoiseReduction";
NSString * _Nonnull const TSAdjustmentKeyNoiseReductionLevel = @"TSAdjustmentNoiseReductionLevel";
NSString * _Nonnull const TSAdjustmentKeyNoiseReductionSharpness = @"TSAdjustmentNoiseReductionSharpness";

NSString * _Nonnull const TSAdjustmentKeySharpen = @"TSAdjustmentSharpen";
NSString * _Nonnull const TSAdjustmentKeySharpenLuminance = @"TSAdjustmentSharpenLuminance";
NSString * _Nonnull const TSAdjustmentKeySharpenRadius = @"TSAdjustmentSharpenRadius";
NSString * _Nonnull const TSAdjustmentKeySharpenIntensity = @"TSAdjustmentSharpenIntensity";


/// context indicating that the date shot has changed
static void *TSLibraryImageDateShotKVOCtx = &TSLibraryImageDateShotKVOCtx;

@interface TSLibraryImage ()

/// cached LibRAW handle for this file. This may be released after a while.
@property (nonatomic, readonly) TSRawImage *libRawHandle;
/// cached ImageIO metadata
@property (nonatomic, readonly) NSDictionary *imageIOMetadata;

- (void) commonInit;
- (void) addKVO;

- (void) loadDefaultAdjustments;
- (void) decodeAdjustmentsData;
- (void) encodeAdjustmentsData;

@end

@implementation TSLibraryImage
@dynamic metadata, fileUrl, fileTypeValue, dayShotValue;
@synthesize libRawHandle = _libRawHandleCache;
@synthesize rotation = _imageRotationFromMetadata;
@synthesize imageIOMetadata = _imageIOMetadataCache;
@synthesize adjustments;

#pragma mark Lifecycle
/**
 * Called when the object is first fetched from a managed object context.
 */
- (void) awakeFromFetch {
	[super awakeFromFetch];
	
	[self commonInit];
	
	// decode the stored adjustments data
	[self decodeAdjustmentsData];
}

/**
 * Called when the object is first inserted into a managed object context.
 */
- (void) awakeFromInsert {
	[super awakeFromInsert];
	
	[self commonInit];
}

/**
 * Removes the KVO observers when the object turns into a fault.
 */
- (void) willTurnIntoFault {
	[super willTurnIntoFault];
	
	// encode the adjustments dictionary
	[self encodeAdjustmentsData];
	
	// remove KVO observers (fuck this shit)
	@try {
		[self removeObserver:self forKeyPath:@"dateShots"];
	} @catch (NSException __unused *exception) { }
	
	// clear caches
	_libRawHandleCache = nil;
	_imageRotationFromMetadata = TSLibraryImageRotationUnknown;
}

/**
 * Common initialization that's performed when the object is fetched or
 * inserted from a store.
 */
- (void) commonInit {
	[self addKVO];
	
	// clear caches
	_imageRotationFromMetadata = TSLibraryImageRotationUnknown;
	
	// set UUID, if applicable
	if(self.uuid == nil) {
		self.uuid = [NSUUID new].UUIDString;
	}
}

/**
 * Loads/creates the default adjustments data.
 */
- (void) loadDefaultAdjustments {
	NSMutableDictionary *filter;
	
	// create adjusments dict
	self.adjustments = [NSMutableDictionary new];
	
	// create exposure adjustments
	filter = [NSMutableDictionary new];
	
	filter[TSAdjustmentKeyExposureEV] = @0.f;
	
	self.adjustments[TSAdjustmentKeyExposure] = filter;
	
	// create noise reduction adjustments
	filter = [NSMutableDictionary new];
	
	filter[TSAdjustmentKeyNoiseReductionLevel] = @0.02f;
	filter[TSAdjustmentKeyNoiseReductionSharpness] = @0.4f;
	
	self.adjustments[TSAdjustmentKeyNoiseReduction] = filter;
	
	// create sharpening adjustments
	filter = [NSMutableDictionary new];
	
	filter[TSAdjustmentKeySharpenLuminance] = @0.4f;
	
	filter[TSAdjustmentKeySharpenRadius] = @2.5f;
	filter[TSAdjustmentKeySharpenIntensity] = @0.5f;
	
	self.adjustments[TSAdjustmentKeySharpen] = filter;
	
	
	// save the data pls
	DDLogDebug(@"Default adjustments for %p: %@", self, self.adjustments);
	[self encodeAdjustmentsData];
}

/**
 * Uses a keyed unarchiver to decode previously saved adjustments data.
 */
- (void) decodeAdjustmentsData {
	// if there is no data to decode, exit
	if(self.rawAdjustmentData == nil) {
		DDLogDebug(@"Setting default adjustment data");
		
		[self loadDefaultAdjustments];
		return;
	}
	
	// decode existing data
	NSKeyedUnarchiver *unarchiver = [NSKeyedUnarchiver unarchiveObjectWithData:self.rawAdjustmentData];
	
	// check version
	NSUInteger ver = [unarchiver decodeIntegerForKey:TSLibraryImageVersionKey];
	
	if(ver < TSLibraryImageVersion) {
		DDLogDebug(@"Upgrading adjustments for %p from 0x%08lx to 0x%08lx", self, ver, TSLibraryImageVersion);
	}
	
	// decode adjustments
	self.adjustments = [unarchiver decodeObjectOfClass:[NSMutableDictionary class] forKey:TSLibraryImageAdjustmentKey];
	
	// finish
	[unarchiver finishDecoding];
}

/**
 * Uses a keyed archiver to encode the current adjustments data.
 */
- (void) encodeAdjustmentsData {
	NSMutableData *d = [NSMutableData new];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:d];
	
	// set the version and data
	[archiver encodeInteger:TSLibraryImageVersion
					 forKey:TSLibraryImageVersionKey];
	
	[archiver encodeObject:self.adjustments
					forKey:TSLibraryImageAdjustmentKey];
	
	// finish
	[archiver finishEncoding];
	
	self.rawAdjustmentData = [d copy];
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
 * KVO handler
 */
- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object
						 change:(NSDictionary<NSString *,id> *) change
						context:(void *) context {
	if(context == TSLibraryImageDateShotKVOCtx) {
		// set the "dayShot" to the date, sans time component
		self.dayShotValue = [self.dateShot timeIntervalSince1970WithoutTime];
	} else {
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
