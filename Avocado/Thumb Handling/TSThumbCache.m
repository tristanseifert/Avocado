//
//  TSThumbCache.m
//  Avocado
//
//  Created by Tristan Seifert on 20160501.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSThumbCache.h"

#import "TSThumbHandlerProtocol.h"
#import "TSHumanModels.h"
#import "TSThumbImageProxy+AvocadoApp.h"

static TSThumbCache *sharedInstance = nil;

@interface TSThumbCache ()

/// xpc connection to the thumb service
@property (nonatomic) NSXPCConnection *xpcConnection;
/// temporary in-memory cache mapping image uuid to thumbnail urls
@property (nonatomic) NSCache *imageCache;

/// Maps a temporary invocation identifier to a callback
@property (nonatomic) NSMutableDictionary <NSString *, TSThumbCacheCallback> *callbackMap;
/// Maps a temporary invocation identifier to an image uuid
@property (nonatomic) NSMutableDictionary <NSString *, NSString *> *imageUuidMap;
/// Queue used to synchronize access to callbackMap
@property (nonatomic, retain) dispatch_queue_t callbackAccessQueue;

@end

@implementation TSThumbCache

/**
 * Returns the shared instance, creating it if needed.
 */
+ (instancetype) sharedInstance {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [TSThumbCache new];
	});
	
	return sharedInstance;
}

/**
 * Initializes the cache.
 */
- (instancetype) init {
	if(self = [super init]) {
		// allocate some in-memory collections
		self.callbackMap = [NSMutableDictionary new];
		self.imageUuidMap = [NSMutableDictionary new];
		
		self.imageCache = [NSCache new];
		
		// Create a queue to synchronize access to the callback map
		self.callbackAccessQueue = dispatch_queue_create("me.tseifert.Avocado.TSThumbCache", DISPATCH_QUEUE_CONCURRENT);
		
		
		// allocate the XPC handle; it will be connected on the first invocation
		NSXPCInterface *intf;
		
		self.xpcConnection = [[NSXPCConnection alloc] initWithServiceName:@"me.tseifert.avocado.ThumbHandler"];
		
		intf = [NSXPCInterface interfaceWithProtocol:@protocol(TSThumbHandlerProtocol)];
		self.xpcConnection.remoteObjectInterface = intf;
		intf = [NSXPCInterface interfaceWithProtocol:@protocol(TSThumbHandlerDelegate)];
		self.xpcConnection.exportedInterface = intf;
		self.xpcConnection.exportedObject = self;
		
		// set up some error handlers
		self.xpcConnection.interruptionHandler = ^{
			DDLogWarn(@"XPC connection to thumb handler invalidated");
		};
		
		// allow the connection to be used
		[self.xpcConnection resume];
	}
	
	return self;
}

/**
 * Clean up some data when deallocating.
 */
- (void) dealloc {
	// invalidate XPC connection
	[self.xpcConnection invalidate];
}

/**
 * Runs a thumb request for the given image, using the specified size. If the
 * image is cached already, the callback is run immediately and no further
 * action is performed.
 *
 * @note There is absolutely no guarantee as to which thread the callback is
 * executed on.
 *
 * @note The callback may be called more than once, with a more fitting
 * thumbnail each time.
 */
- (void) getThumbForImage:(TSLibraryImage *) inImage withSize:(NSSize) size andCallback:(TSThumbCacheCallback) callback {
	__block NSString *inImageUuid = nil;
	
	// get some information from the input image
	[inImage.managedObjectContext performBlockAndWait:^{
		inImageUuid = inImage.uuid;
	}];
	
	// check if the image exists in the cache
	if([self.imageCache objectForKey:inImageUuid] != nil) {
		// if so, immediately return to the callback
		NSImage *image = (NSImage *) [self.imageCache objectForKey:inImageUuid];
		callback(image);
		
		return;
	}
	
	
	// insert the callback into the callback map
	NSString *identifier = [NSUUID new].UUIDString;
	
	dispatch_barrier_async(self.callbackAccessQueue, ^{
		self.callbackMap[identifier] = [callback copy];
		self.imageUuidMap[identifier] = inImageUuid;
	});
	
	// request the XPC thumb generation
	TSThumbImageProxy *proxy = [TSThumbImageProxy proxyForImage:inImage];
	[self.xpcConnection.remoteObjectProxy fetchThumbForImage:proxy
													isUrgent:NO
											  withIdentifier:identifier];
}

#pragma mark XPC Service Callbacks
/**
 * When the thumbnail generation completes successfully for an image previously
 * requested, this callback is executed.
 *
 * @param identifier Value passed to fetchThumbForImage:isUrgent:withIdentifier:
 * @param url Url of the thumbnail image.
 */
- (void) thumbnailGeneratedForIdentifier:(NSString *) identifier atUrl:(NSURL *) url {
	__block NSString *imageUuid = nil;
	__block TSThumbCacheCallback callback;
	
	// get the uuid of the image, and the callback
	dispatch_sync(self.callbackAccessQueue, ^{
		callback = self.callbackMap[identifier];
		imageUuid = self.imageUuidMap[identifier];
	});
	
	// read the image from the url and store in cache
	NSImage *img = [[NSImage alloc] initWithContentsOfURL:url];
	[self.imageCache setObject:img forKey:imageUuid];
	
	// execute callback
	callback(img);
	
	// remove callback from the dictionary
	dispatch_barrier_async(self.callbackAccessQueue, ^{
		[self.callbackMap removeObjectForKey:identifier];
		[self.imageUuidMap removeObjectForKey:identifier];
	});
}

/**
 * If an unexpected error occurs during thumbnail processing (i.e. the file is
 * unreadable, or the raw image does not contain a valid thumbnail) this method
 * is called. If an error is available, it is passed in as well.
 *
 * @param identifier Value passed to fetchThumbForImage:isUrgent:withIdentifier:
 * @param error An `NSError` object describing the error, if applicable.
 */
- (void) thumbnailFailedForIdentifier:(NSString *) identifier withError:(NSError *) error {
	// get the image completion callblack
	__block TSThumbCacheCallback callback;

	dispatch_sync(self.callbackAccessQueue, ^{
		callback = self.callbackMap[identifier];
	});
	
	// execute callback
	NSImage *img = [NSImage imageNamed:NSImageNameCaution];
	callback(img);
	
	DDLogError(@"Error getting thumbnail for %@: %@", identifier, error);
	
	// remove callback from the dictionary
	dispatch_barrier_async(self.callbackAccessQueue, ^{
		[self.callbackMap removeObjectForKey:identifier];
		[self.imageUuidMap removeObjectForKey:identifier];
	});
}

@end
