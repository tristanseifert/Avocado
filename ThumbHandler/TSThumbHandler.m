//
//  TSThumbHandler.m
//  ThumbHandler
//
//  Created by Tristan Seifert on 20160528.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSThumbHandler.h"

#import <MagicalRecord/MagicalRecord.h>

@interface TSThumbHandler ()

/// url to the thumbnail cache directory
@property (readonly, getter=thumbCacheUrl) NSURL *thumbCacheUrl;
/// thumb generation queue
@property (nonatomic) NSOperationQueue *thumbQueue;

/// remote object to receive callbacks
@property (nonatomic, strong) id<TSThumbHandlerDelegate> remote;

- (void) initDiskCache;
- (void) initCoreData;
- (void) initThumbQueue;

@end

@implementation TSThumbHandler

#pragma mark Initialization
/**
 * Sets up a few things upon initialization; namely, the CoreData store in which
 * all the thumbnail metadata is stored, as well as the thumbnail generation
 * queue and the on-disk cache structure.
 *
 * @param remote Object exported by the remote end of the XPC connectionl; this
 * object receives all notifications about completed thumb operations.
 */
- (instancetype) initWithRemote:(id<TSThumbHandlerDelegate>) remote {
	if(self = [super init]) {
		// store reference to remote
		self.remote = remote;
		
		// perform various initializations
		[self initDiskCache];
		[self initCoreData];
		[self initThumbQueue];
	}
	
	return self;
}

/**
 * Sets up the on-disk cache.
 */
- (void) initDiskCache {
	NSError *err = nil;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// create directory, if needed
	[fm createDirectoryAtURL:self.thumbCacheUrl withIntermediateDirectories:YES
				  attributes:nil error:&err];
	
	if(err != nil) {
		DDLogError(@"Couldn't create thumb cache directory: %@", err);
	}
}

/**
 * Initializes the CoreData store.
 */
- (void) initCoreData {
	// get url for store
	NSURL *storeUrl = self.thumbCacheUrl;
	storeUrl = [storeUrl URLByAppendingPathComponent:@"ThumbCache.sqlite"
										 isDirectory:NO];
	
	// create the store
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreAtURL:storeUrl];
	});
}

/**
 * Allocates an operation queue on which thumbnail generation requests will be
 * executed.
 */
- (void) initThumbQueue {
	self.thumbQueue = [NSOperationQueue new];
	
	self.thumbQueue.name = [NSString stringWithFormat:@"TSThumbHandlerQueue %p", self];
	self.thumbQueue.qualityOfService = NSQualityOfServiceBackground;
}

#pragma mark Convenience Properties
/**
 * Returns the url of the thumbnail cache.
 */
- (NSURL *) thumbCacheUrl {
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// query system for url
	NSURL *cachesUrl = [[fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
	cachesUrl = [cachesUrl URLByAppendingPathComponent:@"me.tseifert.Avocado" isDirectory:YES];
	cachesUrl = [cachesUrl URLByAppendingPathComponent:@"TSThumbCache" isDirectory:YES];
	
	return cachesUrl;
}

@end
