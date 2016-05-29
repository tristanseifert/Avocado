//
//  main.m
//  ThumbHandler
//
//  Created by Tristan Seifert on 20160528.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSThumbHandler.h"
#import "TSLogFormatter.h"

@interface TSThumbXPCServiceDelegate : NSObject <NSXPCListenerDelegate>
@end

@implementation TSThumbXPCServiceDelegate

/**
 * Determine whether the connection should be accepted, and if so, sets up the
 * connection and resumes it.
 */
- (BOOL) listener:(NSXPCListener *) listener shouldAcceptNewConnection:(NSXPCConnection *) connection {
	// create the interface and object that's exported
	connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(TSThumbHandlerProtocol)];
	connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(TSThumbHandlerDelegate)];
	
    TSThumbHandler *exportedObject = [[TSThumbHandler alloc] initWithRemote:connection.remoteObjectProxy];
    connection.exportedObject = exportedObject;
    
    // resume connection to allow it to work
    [connection resume];
    return YES;
}

@end

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
	
	// set up the delegate
    TSThumbXPCServiceDelegate *delegate = [TSThumbXPCServiceDelegate new];
    
    // set up the XPC listener
    NSXPCListener *listener = [NSXPCListener serviceListener];
    listener.delegate = delegate;
    
    // resume listener
    [listener resume];
    return 0;
}
