//
//  TSGroupContainerHelper.m
//  Avocado
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSGroupContainerHelper.h"

#import <Security/Security.h>

static TSGroupContainerHelper *sharedInstance = nil;

@interface TSGroupContainerHelper ()

/// Dictionary containing code signature info
@property (nonatomic) NSDictionary *codeSignInfo;
/// App ID for use in the current group container
@property (nonatomic) NSString *containerId;

/// Root URL in group container
@property (nonatomic) NSURL *groupContainerRoot;
/// Application Support directory in group container
@property (nonatomic) NSURL *appSupport;
/// Caches directory in group container
@property (nonatomic) NSURL *caches;

- (void) initDefaultUrls;

@end

@implementation TSGroupContainerHelper

#pragma mark Initialization
/**
 * Returns the singleton instance, creating it if necessary.
 */
+ (instancetype) sharedInstance {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [TSGroupContainerHelper new];
	});
	
	return sharedInstance;
}

/**
 * Reads the entitlements from the binary when initialized, to determine which
 * app group identifiers this app is associated with. It will then pick the
 * first, and create some information about it.
 */
- (instancetype) init {
	if(self = [super init]) {
		OSStatus osErr;
		
		// Get the code object for the main bundle's executable binary file
		NSURL *binaryUrl = [NSBundle mainBundle].executableURL;
		
		SecStaticCodeRef codeRef;
		osErr = SecStaticCodeCreateWithPath((__bridge CFURLRef) binaryUrl,
											kSecCSDefaultFlags, &codeRef);
		
		if(osErr != errSecSuccess) {
			DDLogError(@"SecStaticCodeCreateWithPath failed: %i", (int) osErr);
			return nil;
		}
		
		// Copy codesign info
		CFDictionaryRef _codeSignDict;
		
		SecCSFlags flags = kSecCSRequirementInformation;
		osErr = SecCodeCopySigningInformation(codeRef, flags, &_codeSignDict);
		self.codeSignInfo = (__bridge NSDictionary *) _codeSignDict;
		
		if(osErr != errSecSuccess) {
			DDLogError(@"SecCodeCopySigningInformation failed: %i", (int) osErr);
			return nil;
		}
		
		// Ensure the binary is signed (it really should be)
		if(self.codeSignInfo[(NSString *) kSecCodeInfoIdentifier] == nil) {
			DDLogError(@"Code at %@ isn't signed… wat.", binaryUrl);
			return nil;
		}
		
		// Check that entitlements are exist
		if(self.codeSignInfo[(NSString *) kSecCodeInfoEntitlementsDict] == nil) {
			DDLogError(@"what the fuck, entitlements are nil… Is the binary codesigned?");
			return nil;
		}
		
		// Get the app group identifiers, and pick one
		NSDictionary *entitlements = self.codeSignInfo[(NSString *) kSecCodeInfoEntitlementsDict];
		
		NSArray *appGroups = entitlements[@"com.apple.security.application-groups"];
		
		if(appGroups.count == 0) {
			DDLogError(@"No app groups in entitlements… is the binary codesigned properly?");
			return nil;
		} else if(appGroups.count > 1) {
			DDLogInfo(@"More than one app group identifier in entitlements (%@); chosing first one", appGroups);
		}
		
		self.containerId = appGroups.firstObject;
		
		// Create the default URLs accessible externally
		[self initDefaultUrls];
	}
	
	return self;
}

/**
 * First, gets the URL for the app container; then, the various other URLs (such
 * as the app support) are created.
 */
- (void) initDefaultUrls {
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// Get container URL
	self.groupContainerRoot = [fm containerURLForSecurityApplicationGroupIdentifier:self.containerId];
	
	// Create AppSupport url
	NSURL *appSupport = self.groupContainerRoot;
	appSupport = [appSupport URLByAppendingPathComponent:@"Library" isDirectory:YES];
	appSupport = [appSupport URLByAppendingPathComponent:@"Application Support" isDirectory:YES];
	self.appSupport = appSupport;
	
	// Create AppSupport url
	NSURL *caches = self.groupContainerRoot;
	caches = [caches URLByAppendingPathComponent:@"Library" isDirectory:YES];
	caches = [caches URLByAppendingPathComponent:@"Caches" isDirectory:YES];
	self.caches = caches;
}

@end
