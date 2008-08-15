//
//  DataStore.m
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 07.08.08.
//  Copyright 2008 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import "DataStore.h"


@implementation DataStore


- (id)init {
	if (!(self = [super init])) return nil;
	NSLog(@"datastore init");
	return self;
}


/**
    Returns the support folder for the application, used to store the Core Data
    store file.  This code uses a folder named "CoreDateTemplate" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
    return [basePath stringByAppendingPathComponent:[self applicationName]];
}


- (NSString *)applicationName {
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	return [info valueForKey:@"CFBundleName"];
}

/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
//	NSLog(@"object model: %@", managedObjectModel);
    return managedObjectModel;
}



- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSError *error;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    NSString *filename = [NSString stringWithFormat:@"%@.sqlite", [self applicationName]];
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent:filename]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    

    return persistentStoreCoordinator;
}


 
- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}



- (void)save {
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}



- (void)cleanup {
	NSError *error;
	[self save];
    if (managedObjectContext != nil && [managedObjectContext hasChanges]) {
        [managedObjectContext commitEditing];
		[managedObjectContext save:&error];
	};

    managedObjectContext = nil;
    persistentStoreCoordinator = nil;
    managedObjectModel = nil;
}



@end
