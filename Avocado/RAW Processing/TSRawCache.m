//
//  TSRawCache.m
//  Avocado
//
//  Created by Tristan Seifert on 20160522.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSRawCache.h"

#import <compression.h>

/**
 * Set this define to a nonzero value to print debugging information about
 * the time taken to compress/decompress data.
 */
#define	LogTimings			0

/**
 * Log compression statistics, when set to a nonzero value.
 */
#define	LogCompressionInfo	0


/// number of bytes of uncompressed data per 'stripe' file
const NSInteger TSRawCacheStripeSize = (1024 * 1024) * 48;

/// current version of the cache metadata; low word is minor version
const NSInteger TSRawCacheVersion = 0x00010000;
/// version of the stored cache data
NSString * const TSRawCacheMetadataKeyVersion = @"TSRawCacheVersion";
/// actually stored cache data
NSString * const TSRawCacheMetadataKeyData = @"TSRawCacheData";

/// key for the uncompressed size
NSString * const TSRawCacheUncompressedSizeKey = @"TSRawCacheUncompressedSize";
/// key for the date the object was added
NSString * const TSRawCacheDateAddedKey = @"TSRawCacheDateAdded";
/// key for the date the object was last accessed
NSString * const TSRawCacheDateModifiedKey = @"TSRawCacheDateModified";
/// key for number of stripes into which the data is split
NSString * const TSRawCacheNumStripesKey = @"TSRawCacheNumStripes";

// TODO: Ensure atomicity and thread safety when accessing data structures
@interface TSRawCache ()

/// compression and loading operation queue
@property (nonatomic) NSOperationQueue *queue;

/// URL to the raw cache folder
@property (nonatomic, readonly, getter=rawCacheUrl) NSURL *cacheUrl;
/// dictionary mapping an image uuid -> cache information
@property (nonatomic) NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *cacheMetadata;
/// when set, the cache metadata has been changed
@property (nonatomic) BOOL isCacheMetadataDirty;
/// dictionary containing in-memory caches
@property (nonatomic) NSMutableDictionary<NSString *, NSData *> *cacheData;

- (BOOL) attemptDecodeMetadata;
- (void) encodeCacheMetadata;

- (BOOL) compressData:(NSData *) data toFile:(NSURL *) url;
- (NSData *) decompressDataFromFile:(NSURL *) url;

@end

@implementation TSRawCache

/**
 * Initializes the cache, reading the cache information from any previous
 * execution from disk, or initializing it if it hasn't been created before.
 */
- (instancetype) init {
	if(self = [super init]) {
		// create the cache directory, if necessary
		NSError *err = nil;
		NSFileManager *fm = [NSFileManager defaultManager];
		
		[fm createDirectoryAtURL:self.cacheUrl withIntermediateDirectories:YES
					  attributes:nil error:&err];
		
		if(err != nil) {
			DDLogError(@"Could not create caches directory: %@, %@", self.cacheUrl, err);
			[NSApp presentError:err];
			
			return nil;
		}
		
		// the cache data map (uuid -> NSData) is always created anew
		self.cacheData = [NSMutableDictionary new];
		
		// set up queue
		self.queue = [NSOperationQueue new];
		self.queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
		self.queue.qualityOfService = NSQualityOfServiceUtility;
		
		self.queue.name = @"TSRawCache";
		
		// attempt to decode/load the cache data in the background
		[self.queue addOperationWithBlock:^{
			// try to load it
			if([self attemptDecodeMetadata] == NO) {
				// if it couldn't be loaded, create an empty dictionary
				self.cacheMetadata = [NSMutableDictionary new];
				self.isCacheMetadataDirty = YES;
			}
		}];
	}
	
	return self;
}

/**
 * On de-allocation, check if the cache state is dirty; if so, write the cache
 * to the disk.
 */
- (void) dealloc {
	// write metadata if needed
	if(self.isCacheMetadataDirty) {
		[self encodeCacheMetadata];
	}
	
	// clear some stuff
	self.cacheData = nil;
}

#pragma mark Accessors
/**
 * Checks whether the cache contains any data for the given image.
 */
- (BOOL) hasDataForUuid:(NSString *) uuid {
	return (self.cacheMetadata[uuid] != nil);
}

/**
 * Stores the given data object in the cache for the specified UUID.
 * The data will immediately be compressed and written to disk, but
 * will also be kept around in memory until there is high memory
 * pressure.
 */
- (void) setData:(NSData *) data forUuid:(NSString *) uuid {
	// plop it in the data dict
	self.cacheData[uuid] = data;
	
	// determine how it should be compressed
	NSInteger stripes = ceil((float) data.length / (float) TSRawCacheStripeSize);
	
	// produce a data dictionary
	NSDictionary *info = @{
		TSRawCacheUncompressedSizeKey: @(data.length),
		TSRawCacheDateAddedKey: [NSDate new],
		TSRawCacheDateModifiedKey: [NSDate new],
		
		TSRawCacheNumStripesKey: @(stripes)
	};
	
	self.cacheMetadata[uuid] = info;
	self.isCacheMetadataDirty =  YES;
	
	// save the metadata
	[self.queue addOperationWithBlock:^{
		[self encodeCacheMetadata];
	}];
	
	// queue compression
#if LogTimings
	time_t __tBegin = clock();
#endif
	
	for(NSUInteger i = 0; i < stripes; i++) {
		// create a compression operation and add it to the queue
		[self.queue addOperationWithBlock:^{
			NSString *name;
			NSURL *url;
			NSUInteger offset, length;
			
			// create filename and url
			name = [NSString stringWithFormat:@"%@-%lu.bin", uuid, i];
			url = [self.cacheUrl URLByAppendingPathComponent:name
														isDirectory:NO];
			
			// start an operation to disallow sudden termination
			id activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivitySuddenTerminationDisabled | NSActivityAutomaticTerminationDisabled | NSActivityBackground reason:@"TSRawCache Write"];
			
			// create subdata from the input data
			offset = (i * TSRawCacheStripeSize);
			length = MIN(data.length - offset, TSRawCacheStripeSize);
			
			NSData *subdata = [data subdataWithRange:NSMakeRange(offset, length)];
			
			// perform the compression
			BOOL success = [self compressData:subdata toFile:url];
			
			if(success != YES) {
				DDLogWarn(@"Couldn't compress %@", url);
			}
			
			// end the operation
			[[NSProcessInfo processInfo] endActivity:activity];
			
#if LogTimings
			DDLogDebug(@"Finished %fs", ((double)(clock() - __tBegin)) / CLOCKS_PER_SEC);
#endif
		}];
	}
}

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
- (NSData *) cachedDataForUuid:(NSString *) uuid {
	// is there any data for this image?
	if([self hasDataForUuid:uuid] == NO) {
		return nil;
	}
	
	// check if the data exists in the in-memory data cache
	if(self.cacheData[uuid] != nil) {
		return self.cacheData[uuid];
	}
	
	
	// information for the image exists, but it's not in memory.
	NSMutableDictionary *info = [self.cacheMetadata[uuid] mutableCopy];
	info[TSRawCacheDateModifiedKey] = [NSDate new];
	
	self.cacheMetadata[uuid] = [info copy];
	self.isCacheMetadataDirty = YES;
	
	NSInteger stripes = [info[TSRawCacheNumStripesKey] integerValue];
	
	DDLogVerbose(@"Reading on-disk cache for %@ (%li stripes)", uuid, stripes);
	
	// create a buffer object to hold the full decompressed data
	NSInteger totalSize = [info[TSRawCacheUncompressedSizeKey] integerValue];
	NSMutableData *outBuf = [NSMutableData dataWithLength:totalSize];
	
	
	// decompress each stripe in sequence
#if LogTimings
	time_t __tBegin = clock();
#endif
	
	for(NSUInteger i = 0; i < stripes; i++) {
		NSString *name;
		NSURL *url;
		NSUInteger offset, length;
		
		// create filename and url
		name = [NSString stringWithFormat:@"%@-%lu.bin", uuid, i];
		url = [self.cacheUrl URLByAppendingPathComponent:name
											 isDirectory:NO];
		
		// read and decompress
		NSData *stripeData = [self decompressDataFromFile:url];
		
		if(stripeData != nil) {
			// copy it into the buffer
			offset = (i * TSRawCacheStripeSize);
			length = MIN(totalSize - offset, TSRawCacheStripeSize);
			
			[outBuf replaceBytesInRange:NSMakeRange(offset, length)
							  withBytes:stripeData.bytes
								 length:stripeData.length];
		} else {
			DDLogError(@"Couldn't decompress stripe file %@; skipping", url);
		}
	}
	
	// wait for operations to complete
#if LogTimings
	DDLogDebug(@"Finished %fs", ((double)(clock() - __tBegin)) / CLOCKS_PER_SEC);
#endif
	
	
	// write the metadata to disk at some point in the future
	[self.queue addOperationWithBlock:^{
		[self encodeCacheMetadata];
	}];
	
	// stick it in the in-memory cache
	NSData *data = [outBuf copy];
	
	self.cacheData[uuid] = data;
	return data;
}

/**
 * Evicts all data for a given UUID from the cache. Any compressed
 * data files will also be removed from disk.
 */
- (void) evictDataForUuid:(NSString *) uuid {
	NSError *err = nil;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// ensure there's even data for that uuid
	if([self hasDataForUuid:uuid] == NO) {
		return;
	}
	
	// delete any in-memory data
	[self.cacheData removeObjectForKey:uuid];
	
	
	// get info from the metadata, then delete it
	NSDictionary *info = self.cacheMetadata[uuid];
	NSInteger stripes = [info[TSRawCacheNumStripesKey] integerValue];
	
	[self.cacheMetadata removeObjectForKey:uuid];
	self.isCacheMetadataDirty = YES;
	
	
	// delete each of the stripes from disk
	for(NSUInteger i = 0; i < stripes; i++) {
		NSString *name;
		NSURL *url;
		
		// create filename and url
		name = [NSString stringWithFormat:@"%@-%lu.bin", uuid, i];
		url = [self.cacheUrl URLByAppendingPathComponent:name
											 isDirectory:NO];
		
		// attempt to delete it
		if([fm removeItemAtURL:url error:&err] == NO) {
			DDLogError(@"Error deleting stripe %@: %@", url, err);
		}
	}
	
	// write the metadata to disk at some point in the future
	[self.queue addOperationWithBlock:^{
		[self encodeCacheMetadata];
	}];
}

#pragma mark State Restoration
/**
 * Attempts to decode a stored cache metadata dictionary.
 *
 * @return YES if it was decoded, NO otherwise.
 */
- (BOOL) attemptDecodeMetadata {
	NSURL *url;
	NSData *data;
	NSKeyedUnarchiver *archiver;
	
	// build path to the file
	url = [self.cacheUrl URLByAppendingPathComponent:@"TSRawCache.plist"
										 isDirectory:NO];
	data = [NSData dataWithContentsOfURL:url];
	
	if(data == nil) {
		DDLogDebug(@"Couldn't load cache metadata from %@", url);
		return NO;
	}
	
	// create the unarchiver from the data
	archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	archiver.requiresSecureCoding = YES;
	
	// check version
	NSInteger version = [archiver decodeIntegerForKey:TSRawCacheMetadataKeyVersion];
	
	if((version & 0xFFFF0000) != (TSRawCacheVersion & 0xFFFF0000)) {
		DDLogInfo(@"Discarding outdated cache; is version 0x%08lx, expected 0x%08lx", version, TSRawCacheVersion);
		
		// perform some minimal cleanup
		[archiver finishDecoding];
		return NO;
	} else {
		DDLogDebug(@"Loading cache with version 0x%08lx…", version);
	}
	
	// the data _should_ be alright
	NSSet *classes = [NSSet setWithObjects:[NSDictionary class], [NSMutableDictionary class], [NSDate class], [NSNumber class], nil];
	
	self.cacheMetadata = [archiver decodeObjectOfClasses:classes forKey:TSRawCacheMetadataKeyData];
	self.isCacheMetadataDirty = NO;
	
	// finish up
	[archiver finishDecoding];
	
	return YES;
}

/**
 * Encodes the cache information, then stores it on disk.
 */
- (void) encodeCacheMetadata {
	NSError *err = nil;
	NSURL *url;
	NSMutableData *data;
	NSKeyedArchiver *archiver;
	
	// start an activity
	id activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivitySuddenTerminationDisabled | NSActivityAutomaticTerminationDisabled | NSActivityBackground reason:@"TSRawCache Metadata Write"];
	
	// build path to the file and data to write into
	url = [self.cacheUrl URLByAppendingPathComponent:@"TSRawCache.plist"
										 isDirectory:NO];
	
	data = [NSMutableData new];
	
	// set up archiver
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	archiver.requiresSecureCoding = YES;
	
	// encode version
	[archiver encodeInteger:TSRawCacheVersion
					 forKey:TSRawCacheMetadataKeyVersion];
	
	// encode metadata dictionary
	[archiver encodeObject:self.cacheMetadata
					forKey:TSRawCacheMetadataKeyData];
	
	// finish, write to disk
	[archiver finishEncoding];
	
	if([data writeToURL:url options:NSDataWritingAtomic error:&err] == NO) {
		DDLogError(@"Couldn't write cache data to disk: %@", err);
	} else {
		// mark cache as clean
		self.isCacheMetadataDirty = NO;
	}
	
	// finish the activity
	[[NSProcessInfo processInfo] endActivity:activity];
}

#pragma mark Compression
/**
 * Uses libcompression to compress the given block of data using Apple's LZFSE
 * compression algorithm. The compressor will operate in stream mode, working
 * on fixed-size chunks of data at a time.
 */
- (BOOL) compressData:(NSData *) data toFile:(NSURL *) url {
	compression_status status;
	compression_stream stream;
	compression_stream_flags flags = (compression_stream_flags) 0;
	
	NSFileHandle *fd;
	NSError *err = nil;
	
#if LogCompressionInfo
	NSUInteger totalBytesWritten = 0;
	
	DDLogVerbose(@"Compressing %lu bytes to %@", data.length, url);
#endif
	
	// create the file, if needed
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if([fm createFileAtPath:url.path contents:[NSData new] attributes:nil] == NO) {
		DDLogError(@"Couldn't create file at %@", url.path);
		return NO;
	}
	
	// try to create a file descriptor
	fd = [NSFileHandle fileHandleForWritingToURL:url error:&err];
	
	if(fd == nil || err != nil) {
		DDLogError(@"Error creating writing file handle for url %@: %@", url, err);
		return NO;
	}
	
	[fd seekToFileOffset:0];
	
	// set up compression
	status = compression_stream_init(&stream, COMPRESSION_STREAM_ENCODE, COMPRESSION_LZFSE);
	
	if(status != COMPRESSION_STATUS_OK) {
		DDLogError(@"Error initializing compression: %i", status);
		return NO;
	}
	
	// populate the input data pointers
	stream.src_ptr = (const uint8_t *) data.bytes;
	stream.src_size = data.length;
	
	// allocate an output buffer and set its information
	NSUInteger chunkSize = (512 * 1024);
	NSMutableData *outChunk = [NSMutableData dataWithLength:chunkSize];
	
	stream.dst_ptr = (uint8_t *) outChunk.mutableBytes;
	stream.dst_size = chunkSize;
	
	// actually compress the data
	do {
		// is the input buffer empty?
		if(stream.src_size == 0) {
			flags = COMPRESSION_STREAM_FINALIZE;
#if LogCompressionInfo
			DDLogVerbose(@"Finalizing compression…");
#endif
		}
		
		// perform an iteration of the compression algorithm
		status = compression_stream_process(&stream, flags);
		
		switch(status) {
			// if status is ok, write the block out
			case COMPRESSION_STATUS_OK:
				// the entire output chunk was written
				if(stream.dst_size == 0) {
					[fd writeData:outChunk];
#if LogCompressionInfo
					totalBytesWritten += chunkSize;
#endif
					
					// Re-use output buffer
					stream.dst_ptr = (uint8_t *) outChunk.mutableBytes;
					stream.dst_size = chunkSize;
				}
				
				break;
				
			// if status is end, calculate how many bytes to actually write
			case COMPRESSION_STATUS_END: {
				// some data were compressed, but less than the chunk size
				if (stream.dst_ptr > ((uint8_t *) outChunk.mutableBytes)) {
					// calculate how many bytes to write
					NSUInteger bytesToWrite = stream.dst_ptr - ((uint8_t *) outChunk.mutableBytes);
					outChunk.length = bytesToWrite;
					
					// write that much to the file
					[fd writeData:outChunk];
					
#if LogCompressionInfo
					totalBytesWritten += bytesToWrite;
#endif
				}
				
				break;
			}
				
			// lastly, handle an error
			default:
				DDLogError(@"Error occurred while compressing");
				return NO;
		}
	} while(status == COMPRESSION_STATUS_OK);

#if LogCompressionInfo
	DDLogDebug(@"Wrote %lu bytes (uncompressed = %lu) to %@; compression factor = %3.4f", totalBytesWritten, data.length, url, ((float) data.length / (float) totalBytesWritten));
#endif
	
	// clean up output stream
	[fd closeFile];
	
	// clean up compression
	compression_stream_destroy(&stream);
	return YES;
}

/**
 * Uses libcompression, using the LZFSE algorithm, to decompress the data in
 * the given file; the method will return an NSData object that is precisely
 * the number of bytes of the compressed file, or nil if an error occurred.
 */
- (NSData *) decompressDataFromFile:(NSURL *) url {
	compression_status status;
	compression_stream stream;
	compression_stream_flags flags = (compression_stream_flags) 0;
	
	NSFileHandle *fd;
	NSError *err = nil;
	
	// try to create a file descriptor
	fd = [NSFileHandle fileHandleForReadingFromURL:url error:&err];
	
	if(fd == nil || err != nil) {
		DDLogError(@"Error creating reading file handle for url %@: %@", url, err);
		return NO;
	}
	
	[fd seekToFileOffset:0];
	
	
	// set up compression
	status = compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_LZFSE);
	
	if(status != COMPRESSION_STATUS_OK) {
		DDLogError(@"Error initializing compression: %i", status);
		return NO;
	}
	
	// set up an input (read) buffer
	NSUInteger readBufSz = (1024 * 1024);
	NSData *readBuf;
	
	// set up an output buffer, which is appended to the final output
	NSUInteger outBufSz = (1024 * 1024);
	NSMutableData *outBuf = [NSMutableData dataWithLength:outBufSz];
	
	stream.dst_ptr = (uint8_t *) outBuf.mutableBytes;
	stream.dst_size = outBufSz;
	
	// decompressed data is appended to this data object
	NSMutableData *decompressedData = [NSMutableData new];
	
	// perform decompression
	do {
		// if all data was consumed on the last iteration, read some more
		if(stream.src_size == 0) {
			// read up to `readBufSz` bytes
			readBuf = [fd readDataOfLength:readBufSz];
			
			// set the buffer
			stream.src_ptr = (uint8_t *) readBuf.bytes;
			stream.src_size = readBuf.length;
		}
		
		// perform an iteration of the compression algorithm
		status = compression_stream_process(&stream, flags);

		// handle result of the compression function
		switch(status) {
			// if status is ok, write the block out
			case COMPRESSION_STATUS_OK:
				// the entire output buffer was filled
				if(stream.dst_size == 0) {
					[decompressedData appendData:outBuf];
					
					// Re-use output buffer
					stream.dst_ptr = (uint8_t *) outBuf.mutableBytes;
					stream.dst_size = outBufSz;
				}
				
				break;
				
			// the end has been reached; figure out how much was decompressed
			case COMPRESSION_STATUS_END: {
				// some data were compressed, but less than the chunk size
				if (stream.dst_ptr > ((uint8_t *) outBuf.mutableBytes)) {
					// calculate how many bytes to append
					NSUInteger bytesDecompressed = stream.dst_ptr - ((uint8_t *) outBuf.mutableBytes);
					outBuf.length = bytesDecompressed;
					
					// append that to the data
					[decompressedData appendData:outBuf];
				}
				
				break;
			}
				
			// lastly, handle an error
			default:
				DDLogError(@"Error occurred while decompressing");
				return NO;
		}
	} while(status == COMPRESSION_STATUS_OK);
	
	// clean up output stream
	[fd closeFile];
	
	// clean up compression
	compression_stream_destroy(&stream);
	return [decompressedData copy];
}

#pragma mark Convenience Properties
/**
 * Gets the URL to the raw cache.
 */
- (NSURL *) rawCacheUrl {
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// query system for url
	NSURL *cachesUrl = [[fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
	cachesUrl = [cachesUrl URLByAppendingPathComponent:@"me.tseifert.Avocado" isDirectory:YES];
	cachesUrl = [cachesUrl URLByAppendingPathComponent:@"TSRawPipeline" isDirectory:YES];
	
	return cachesUrl;
}

@end
