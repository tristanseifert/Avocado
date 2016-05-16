//
//  TSTTYLogFormatter.h
//  Avocado
//
//  Created by Tristan Seifert on 20160516.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSLogTTYFormatter : NSObject <DDLogFormatter> {
	NSDateFormatter *_dateFormatter;
}

@end

@interface TSLogFileFormatter : NSObject <DDLogFormatter> {
	NSDateFormatter *_dateFormatter;
}

@end
