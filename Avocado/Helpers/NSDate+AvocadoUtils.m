//
//  NSDate+AvocadoUtils.m
//  Avocado
//
//  Created by Tristan Seifert on 20160430.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import "NSDate+AvocadoUtils.h"

@interface NSDate (AvocadoUtilsPrivate)

- (NSDate *) dateWithoutTime;

@end

@implementation NSDate (AvocadoUtils)

/**
 * Returns a time interval, since a reference date, without a time component.
 */
- (NSTimeInterval) timeIntervalSince1970WithoutTime {
	return [self dateWithoutTime].timeIntervalSince1970;
}

/**
 * Creates a date, without the time component.
 */
- (NSDate *) dateWithoutTime {
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];
	return [calendar dateFromComponents:components];
}

@end
