//
//  TSLFCamera.mm
//  Avocado
//
//  Created by Tristan Seifert on 20160526.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLFCamera.h"
#import "TSLFDatabase.h"

#import "lensfun.h"

NSString* const TSLFCameraKeyMake = @"TSLFCameraMake";
NSString* const TSLFCameraKeyModel = @"TSLFCameraModel";
NSString* const TSLFCameraKeyCropFactor = @"TSLFCameraCropFactor";

@interface TSLFCamera ()

@property (nonatomic) lfCamera *camera;

- (BOOL) isEqualToCamera:(TSLFCamera *) camera;

@end

@implementation TSLFCamera

/**
 * Creates a camera object.
 */
- (instancetype) initWithCamera:(void *) camera {
	if(self = [super init]) {
		self.camera = (lfCamera *) camera;
	}
	
	return self;
}

/**
 * Frees the internal camera object on deallocation.
 */
- (void) dealloc {
	delete self.camera;
}

/**
 * Reads the maker string from the camera object.
 */
- (NSString *) maker {
	NSLocale *loc = [NSLocale currentLocale];
	return [TSLFDatabase stringForLocale:loc inLFString:self.camera->Maker];
}

/**
 * Reads the model string from the camera object.
 */
- (NSString *) model {
	NSLocale *loc = [NSLocale currentLocale];
	return [TSLFDatabase stringForLocale:loc inLFString:self.camera->Model];
}

/**
 * Returns the crop factor of this camera's sensor. The crop factor is the
 * sensor's relative size, when compared to a standard 35mm film frame.
 */
- (CGFloat) cropFactor {
	return self.camera->CropFactor;
}

/**
 * Puts together a camera display name (shown in the UI) from a variety of other
 * parameters.
 */
- (NSString *) displayName {
	NSString *localizedString = NSLocalizedString(@"%@ %@", @"Camera display name; 1 = maker, 2 = model");
	return [NSString localizedStringWithFormat:localizedString, self.maker, self.model];
}


/**
 * Archives a few key parameters, which can later be used to (at least attempt
 * to) find this lens again.
 */
- (NSData *) persistentData {
	// Set up an archiver
	NSMutableData *data = [NSMutableData new];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	
	archiver.requiresSecureCoding = YES;
	
	// Archive several key properties
	const char *make = self.camera->Maker;
	NSUInteger makeLength = strlen(make);
	NSData *makeData = [NSData dataWithBytes:make length:makeLength];
	[archiver encodeObject:makeData forKey:TSLFCameraKeyMake];
	
	const char *model = self.camera->Model;
	NSUInteger modelLength = strlen(model);
	NSData *modelData = [NSData dataWithBytes:model length:modelLength];
	[archiver encodeObject:modelData forKey:TSLFCameraKeyModel];
	
	[archiver encodeDouble:self.camera->CropFactor forKey:TSLFCameraKeyCropFactor];
	
	// Complete archival process
	[archiver finishEncoding];
	return [data copy];
}

#pragma mark Collection Support
/**
 * Compares to see whether this object is equivalent to another camera. This 
 * performs a comparison on the maker, model, and crop factor.
 */
- (BOOL) isEqualToCamera:(TSLFCamera *) camera {
	// Check maker
	if([self.maker isEqualToString:camera.maker] == NO)
		return NO;
	
	// Check model
	if([self.model isEqualToString:camera.model] == NO)
		return NO;
	
	// Check maker
	if(self.cropFactor != camera.cropFactor)
		return NO;
	
	// The objects must be equal.
	return YES;
}

/**
 * Implements the more general equality comparison method.
 */
- (BOOL) isEqual:(id) object {
	// Check identity (pointer)
	if(self == object) {
		return YES;
	}
	
	// If the class is not the same as this class, they're not equal
	if(![object isKindOfClass:[TSLFCamera class]]) {
		return NO;
	}
	
	// If it is an TSLFCamera instance, check deep equality
	return [self isEqualToCamera:(TSLFCamera *) object];
}

/**
 * Returns a hash for this object. This is a bitwise XOR of the maker and model
 * strings. (This is acceptable, because they can never be swapped.)
 */
- (NSUInteger) hash {
	return self.maker.hash ^ self.model.hash;
}

/**
 * Returns a description for this camera, consisting of its address,
 */
- (NSString *) description {
	return [NSString stringWithFormat:@"TSLFCamera<%p> maker = %@, model = %@", self, self.maker, self.model];
}

@end
