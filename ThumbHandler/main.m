//
//  main.m
//  ThumbHandler
//
//  Created by Tristan Seifert on 20160528.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSThumbHandler.h"

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
	
    TSThumbHandler *exportedObject = [TSThumbHandler new];
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
    TSThumbXPCServiceDelegate *delegate = [TSThumbXPCServiceDelegate new];
    
    // set up the XPC listener
    NSXPCListener *listener = [NSXPCListener serviceListener];
    listener.delegate = delegate;
    
    // resume listener
    [listener resume];
    return 0;
}
