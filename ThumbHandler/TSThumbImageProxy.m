//
//  TSThumbImageProxy.m
//  Avocado
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSThumbImageProxy.h"

@interface TSThumbImageProxy ()

/// bookmark data for the url
@property (nonatomic) NSData *originalUrlBookmark;

@end

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
		
		// decode the url data; this automagically makes the url on access
		self.originalUrlBookmark = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"urlBookmark"];
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
	
	[aCoder encodeObject:self.originalUrlBookmark forKey:@"urlBookmark"];
}

+ (BOOL) supportsSecureCoding {
	return YES;
}

#pragma mark URL Handling
/**
 * When setting the original URL, create an app-scoped bookmark, and set its
 * data.
 */
- (void) setOriginalUrl:(NSURL *) inUrl {
	NSError *err = nil;
	
	// create bookmark
	self.originalUrlBookmark = [inUrl bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope | NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
									 includingResourceValuesForKeys:nil
													  relativeToURL:nil error:&err];
	
	// check for error
	if(err != nil) {
		DDLogError(@"Couldn't create bookmark for url %@: %@", inUrl, err);
	}
}

/**
 * Decodes the bookmark data to yield an URL.
 */
- (NSURL *) originalUrl {
	// check if we have bookmark data
	if(self.originalUrlBookmark == nil) {
		return nil;
	}
	
	BOOL isStale = NO;
	NSError *err = nil;
	NSURL *url = nil;
	
	// try to re-create the url
	url = [NSURL URLByResolvingBookmarkData:self.originalUrlBookmark
									options:NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithSecurityScope
							  relativeToURL:nil bookmarkDataIsStale:&isStale
									  error:&err];
	
	if(err != nil) {
		DDLogError(@"Could not decode url bookmark: %@", err);
		return nil;
	} else if(isStale == YES) {
		DDLogWarn(@"Decoded URL (%@) is stale (this should never happen)", url);
	}
	
	// returns the url
	return url;
}

/**
 * Allow for KVO on the originalUrl key path.
 */
+ (NSSet *) keyPathsForValuesAffectingOriginalUrl {
	return [NSSet setWithObject:@"originalUrlBookmark"];
}

@end
