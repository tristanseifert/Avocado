//
//  main.m
//  ThumbHandler
//
//  Created by Tristan Seifert on 20160528.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSThumbXPCServiceDelegate.h"
#import "TSLogFormatter.h"

static void TSCreateThumbDirectories();

/**
 * Entry point for the XPC service. Sets up an XPC listener with the delegate.
 */
int main(int argc, const char *argv[]) {
	// set up logging
	DDTTYLogger *tty = [DDTTYLogger sharedInstance];
	tty.colorsEnabled = YES;
	tty.logFormatter = [TSLogTTYFormatter new];
	[DDLog addLogger:tty];
	
	DDASLLogger *asl = [DDASLLogger sharedInstance];
	asl.logFormatter = [TSLogTTYFormatter new];
	[DDLog addLogger:asl];
	
	DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
	fileLogger.rollingFrequency = 60 * 60 * 24;
	fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
	fileLogger.logFormatter = [TSLogFileFormatter new];
	[DDLog addLogger:fileLogger];
	
	// create thumbnail directories
	TSCreateThumbDirectories();
	
	// set up the delegate and XPC listener
    TSThumbXPCServiceDelegate *delegate = [TSThumbXPCServiceDelegate new];
	
    NSXPCListener *listener = [NSXPCListener serviceListener];
    listener.delegate = delegate;
    
    // resume listener
    [listener resume];
    return 0;
}

/**
 * Creates the thumbnail directories.
 */
static void TSCreateThumbDirectories() {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *err = nil;
	
	// get the root cache url
	NSURL *cacheUrl = [[fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
	cacheUrl = [cacheUrl URLByAppendingPathComponent:@"me.tseifert.Avocado" isDirectory:YES];
	cacheUrl = [cacheUrl URLByAppendingPathComponent:@"TSThumbCache" isDirectory:YES];
	
	// iterate 256 times to create all of them
	for(NSUInteger i = 0; i < 256; i++) {
		NSString *dirName = [NSString stringWithFormat:@"%08lx", (unsigned long) i];
		
		// create the directory
		NSURL *dirUrl = [cacheUrl URLByAppendingPathComponent:dirName isDirectory:YES];
		
		[fm createDirectoryAtURL:dirUrl withIntermediateDirectories:YES
					  attributes:nil error:&err];
		
		if(err != nil) {
			DDLogError(@"Couldn't create thumb cache directory at %@: %@", cacheUrl, err);
		}
	}
}
