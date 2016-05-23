//
//  TSRawCache.h
//  Avocado
//
//	This class holds both in-memory representations of cached bitmap
//	data (in floating-point, planar format) as well as handles writing
//	them to the disk transparently. It maintains an internal catalogue
//	of information regarding which caches exist, how large they are, and
//	what images they correspond to.
//
//	When storage becomes low on the system, or the cache becomes too
//	large, the cache will automagically decide which files should be
//	dropped from the cache.
//
//	When storing image planes in the cache, they are automagically kept
//	in memory for as long as feasible; when they are evicted due to
//	memory pressure, or the system is idle, the data is persisted to
//	disk, with some compression applied.
//
//  Created by Tristan Seifert on 20160522.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSRawCache : NSObject

/**
 * Checks whether the cache contains any data for the given image.
 */
- (BOOL) hasDataForUuid:(NSString *) uuid;

/**
 * Stores the given data object in the cache for the specified UUID.
 * The data will immediately be compressed and written to disk, but
 * will also be kept around in memory until there is high memory
 * pressure.
 */
- (void) setData:(NSData *) data forUuid:(NSString *) uuid;

/**
 * Returns a data object that was previously stored for an image with
 * the given uuid. This function will do one of three things:
 *
 *	 1. Return an in-memory copy of the cache. This is fastest, but
 *		this behaviour shouldn't be relied on, particularly if the
 *		system is under memory pressure.
 *	 2. Loads and decompresses data previously written to disk. This
 *		will take place if the cache contains metadata information
 *		for the given image. In this case, the method will be fully
 *		synchronous. Decompression could take a few seconds, and will
 *		block the calling thread.
 *	 3. Return nil, if no information about the given image could be
 *		found in the metadata cache. This is guaranteed to ocurr only
 *		when `hasDataForUuid:` returns NO.
 */
- (NSData *) cachedDataForUuid:(NSString *) uuid;

/**
 * Evicts all data for a given UUID from the cache. Any compressed
 * data files will also be removed from disk.
 */
- (void) evictDataForUuid:(NSString *) uuid;

@end
