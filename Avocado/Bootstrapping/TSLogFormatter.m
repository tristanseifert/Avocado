//
//  TSTTYLogFormatter.m
//  Avocado
//
//  Created by Tristan Seifert on 20160516.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSLogFormatter.h"

@implementation TSLogTTYFormatter

- (id) init {
	if((self = [super init])) {
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[_dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
	}
	return self;
}

- (NSString *) formatLogMessage:(DDLogMessage *) logMessage {
	NSString *logLevel;
	
	switch (logMessage->_flag) {
		case DDLogFlagError		: logLevel = @"ERROR"; break;
		case DDLogFlagWarning	: logLevel = @" WARN"; break;
		case DDLogFlagInfo		: logLevel = @" INFO"; break;
		case DDLogFlagDebug		: logLevel = @"DEBUG"; break;
		default					: logLevel = @" VERB"; break;
	}
	
	NSString *timestamp = [_dateFormatter stringFromDate:(logMessage->_timestamp)];
	
	// <level>: <date> | <file>:<line> <message>
//	return [NSString stringWithFormat:@"%@: %@ | %s:%i | %@", logLevel, timestamp,
//			logMessage->file, logMessage->lineNumber, logMessage->_message];
	return [NSString stringWithFormat:@"%@: %@ | %@ | %@", logLevel, timestamp,
			logMessage->_function, logMessage->_message];
}

@end

@implementation TSLogFileFormatter

- (id) init {
	if((self = [super init])) {
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[_dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
	}
	return self;
}

- (NSString *) formatLogMessage:(DDLogMessage *) logMessage {
	NSString *logLevel;
	
	switch (logMessage->_flag) {
		case DDLogFlagError		: logLevel = @"ERROR"; break;
		case DDLogFlagWarning	: logLevel = @" WARN"; break;
		case DDLogFlagInfo		: logLevel = @" INFO"; break;
		case DDLogFlagDebug		: logLevel = @"DEBUG"; break;
		default					: logLevel = @" VERB"; break;
	}
	
	NSString *timestamp = [_dateFormatter stringFromDate:(logMessage->_timestamp)];
	
	// <level>: <date> | <func>(<file>:<line>) <thread> <message>
	return [NSString stringWithFormat:@"%@: %@ | %@ (%@:%lu) %@ | %@", logLevel,
			timestamp, logMessage->_function, logMessage->_file,
			(unsigned long) logMessage->_line, logMessage->_threadName,
			logMessage->_message];
	
	/*return [NSString stringWithFormat:@"%@: %@ | %s (%@) | %@", logLevel,
			timestamp, logMessage->function, logMessage->threadName,
			logMessage->logMsg];*/
}

@end
