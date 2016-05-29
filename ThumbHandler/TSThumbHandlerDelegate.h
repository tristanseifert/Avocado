//
//  TSThumbHandlerDelegate.h
//  Avocado
//
//  Created by Tristan Seifert on 20160529.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Callers of the thumb handler (i.e. the main app) should implement this
 * protocol, then export themselves to the other end of the connection, so that
 * they can be notified when a thumbnail operation has completed.
 */
@protocol TSThumbHandlerDelegate <NSObject>

@end
