//
//  TSThumbXPCServiceDelegate.m
//  Avocado
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "TSThumbXPCServiceDelegate.h"
#import "TSThumbHandler.h"

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
