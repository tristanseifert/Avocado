#import "TSLibraryImage.h"

#import "NSDate+AvocadoUtils.h"

/// context indicating that the date shot has changed
static void *TSLibraryImageDateShotKVOCtx = &TSLibraryImageDateShotKVOCtx;

@interface TSLibraryImage ()

- (void) addKVO;

@end

@implementation TSLibraryImage
@dynamic metadata, fileUrl, fileTypeValue, dayShotValue;

#pragma mark Lifecycle
/**
 * Called when the object is first fetched from a managed object context.
 */
- (void) awakeFromFetch {
	[super awakeFromFetch];
	
	[self addKVO];
}

/**
 * Called when the object is first inserted into a managed object context.
 */
- (void) awakeFromInsert {
	[super awakeFromInsert];
	
	[self addKVO];
}

/**
 * Removes the KVO observers when the object turns into a fault.
 */
- (void) willTurnIntoFault {
	[super willTurnIntoFault];
	
	[self removeObserver:self forKeyPath:@"dateShots"];
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

@end
