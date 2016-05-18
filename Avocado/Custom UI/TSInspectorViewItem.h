//
//  TSInspectorViewItem.h
//  Avocado
//
//  Created by Tristan Seifert on 20160514.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSInspectorViewItem : NSViewController

/**
 * Sets up an inspector view item, using the given view controller as the
 * content.
 */
+ (instancetype) itemWithContentController:(NSViewController *) content expanded:(BOOL) expanded;

/// whether the item is expanded or not
@property (nonatomic, readwrite) BOOL expanded;

/// content view controller
@property (nonatomic, readonly) NSViewController *content;

@end
