//
//  DataStore.h
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 07.08.08.
//  Copyright 2008-2009 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DataStore : NSObject {
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
- (NSString *)applicationName;
- (void)cleanup;
- (void)save;
- (NSUInteger)countForEntityNamed:(NSString *)name;
- (NSManagedObject *)firstEntityNamed:(NSString *)name;
- (NSFetchRequest *)fetchRequestForEntityNamed:(NSString *)name;
- (void)deleteObject:(NSManagedObject *)object;


@end
