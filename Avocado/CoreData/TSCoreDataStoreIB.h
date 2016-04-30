//
//  TSCoreDataStoreIB.h
//  Avocado
//
//	A custom object that can be instantiated in Interface Builder to provide
//	access to a managed object context whose thread affinity is to the main
//	queue.
//
//  Created by Tristan Seifert on 20160429.
//  Copyright © 2016 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface TSCoreDataStoreIB : NSObject

@property (nonatomic, readonly) NSManagedObjectContext *moc;

@end
