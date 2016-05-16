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
	
	// start application
	return NSApplicationMain(argc, argv);
}
