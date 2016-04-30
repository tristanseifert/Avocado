//
//  NSDate+AvocadoUtils.h
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (AvocadoUtils)

/**
 * Returns a time interval, since a reference date, without a time component.
 */
- (NSTimeInterval) timeIntervalSince1970WithoutTime;

@end
