//
//  main.m
//  Avocado
//
//  Created by Tristan Seifert on 20160428.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
	// set up logging
	DDTTYLogger *tty = [DDTTYLogger sharedInstance];
	tty.colorsEnabled = YES;
	[DDLog addLogger:tty];
	
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	
	DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
	fileLogger.rollingFrequency = 60 * 60 * 24;
	fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
	[DDLog addLogger:fileLogger];
	
	// start application
	return NSApplicationMain(argc, argv);
}
