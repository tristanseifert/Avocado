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

#import "TSGroupContainerHelper.h"

static void TSCreateThumbDirectories();

/**
 * Entry point for the XPC service. Sets up an XPC listener with the delegate.
 */
int main(int argc, const char *argv[]) {
	// Set up the TTY logger
	DDTTYLogger *tty = [DDTTYLogger sharedInstance];
	tty.colorsEnabled = YES;
	tty.logFormatter = [TSLogTTYFormatter new];
	[DDLog addLogger:tty];
	
	// Define a colour scheme for the logger
	[tty setForegroundColor:[NSColor colorWithCalibratedRed:0.839f green:0.224f blue:0.118f alpha:1.0f]
			backgroundColor:nil forFlag:DDLogFlagError];
	[tty setForegroundColor:[NSColor colorWithCalibratedRed:0.8f green:0.475f blue:0.125f alpha:1.0f]
			backgroundColor:nil forFlag:DDLogFlagWarning];
	[tty setForegroundColor:[NSColor colorWithCalibratedRed:0.f green:0.f blue:0.8f alpha:1.f]
			backgroundColor:nil forFlag:DDLogFlagInfo];
	[tty setForegroundColor:[NSColor colorWithCalibratedRed:0.4f green:0.4f blue:0.4f alpha:1.0f]
			backgroundColor:nil forFlag:DDLogFlagDebug];
	[tty setForegroundColor:[NSColor colorWithCalibratedRed:0.6f green:0.6f blue:0.6f alpha:1.0f]
			backgroundColor:nil forFlag:DDLogFlagVerbose];
	
	// Set up logging to the Apple System Log
	DDASLLogger *asl = [DDASLLogger sharedInstance];
	asl.logFormatter = [TSLogTTYFormatter new];
	[DDLog addLogger:asl];
	
	// Lastly, log to a file
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
	NSURL *cacheUrl = [TSGroupContainerHelper sharedInstance].caches;
	cacheUrl = [cacheUrl URLByAppendingPathComponent:@"TSThumbCache" isDirectory:YES];
	
	// iterate 256 times to create all of them
	for(NSUInteger i = 0; i < 256; i++) {
		NSString *dirName = [NSString stringWithFormat:@"thumb-%02lx", (unsigned long) i];
		
		// create the directory
		NSURL *dirUrl = [cacheUrl URLByAppendingPathComponent:dirName isDirectory:YES];
		
		[fm createDirectoryAtURL:dirUrl withIntermediateDirectories:YES
					  attributes:nil error:&err];
		
		if(err != nil) {
			DDLogError(@"Couldn't create thumb cache directory at %@: %@", cacheUrl, err);
		}
	}
}
