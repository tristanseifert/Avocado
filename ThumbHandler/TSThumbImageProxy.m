//
//  TSThumbImageProxy.m
//  Avocado
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSThumbImageProxy.h"

@implementation TSThumbImageProxy

#pragma NSCoding Support
/**
 * Decodes the object's properties.
 */
- (instancetype) initWithCoder:(NSCoder *) aDecoder {
	if(self = [super init]) {
		self.uuid = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"uuid"];
		
		NSValue *size = [aDecoder decodeObjectOfClass:[NSValue class] forKey:@"size"];
		self.size = size.sizeValue;
		
		self.isRaw = [aDecoder decodeBoolForKey:@"isRaw"];
		
		// decode the url bookmark data previously generated
		NSData *bookmark = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"urlBookmark"];
		
		BOOL isStale = NO;
		NSError *err = nil;
		NSURL *url = nil;
		
		url = [NSURL URLByResolvingBookmarkData:bookmark
										options:NSURLBookmarkResolutionWithoutUI
								  relativeToURL:nil bookmarkDataIsStale:&isStale
										  error:&err];
		
		if(err != nil) {
			DDLogError(@"Could not decode url bookmark data: %@", err);
			return nil;
		} else if(isStale == YES) {
			DDLogWarn(@"Decoded URL (%@) is stale (this should never happen)", url);
		}
		
		self.originalUrl = url;
	}
	
	return self;
}

/**
 * Encodes the object's properties.
 */
- (void) encodeWithCoder:(NSCoder *) aCoder {
	[aCoder encodeObject:self.uuid forKey:@"uuid"];
	[aCoder encodeObject:[NSValue valueWithSize:self.size] forKey:@"size"];
	[aCoder encodeBool:self.isRaw forKey:@"isRaw"];
	
	// create a bookmark for the url, and archive that instead of the raw url
	NSData *bookmark;
	NSError *err = nil;
	
	bookmark = [self.originalUrl bookmarkDataWithOptions:0
						  includingResourceValuesForKeys:nil
										   relativeToURL:nil error:&err];
	
	if(err != nil) {
		DDLogError(@"Couldn't create bookmark for url %@: %@", self.originalUrl, err);
	}
	
	[aCoder encodeObject:bookmark forKey:@"urlBookmark"];
}

+ (BOOL) supportsSecureCoding {
	return YES;
}
@end
