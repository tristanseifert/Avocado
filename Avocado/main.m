//
//  main.m
//  Avocado
//
//  Created by Tristan Seifert on 20160428.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSLogFormatter.h"

int main(int argc, const char * argv[]) {
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
	
	// Start application
	return NSApplicationMain(argc, argv);
}
