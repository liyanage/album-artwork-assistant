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
	return self;
}


- (NSString *)applicationSupportFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
    return [basePath stringByAppendingPathComponent:[self applicationName]];
}


- (NSString *)applicationName {
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	return [info valueForKey:@"CFBundleName"];
}


- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
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



- (NSUInteger)countForEntityNamed:(NSString *)name {
	NSFetchRequest *request = [self fetchRequestForEntityNamed:name];
	if (!request) return 0;
	id moc = [self managedObjectContext];
	return [moc countForFetchRequest:request error:nil];
}



- (NSManagedObject *)firstEntityNamed:(NSString *)name {
	NSFetchRequest *request = [self fetchRequestForEntityNamed:name];
	if (!request) return nil;
	[request setFetchLimit:1];
	id moc = [self managedObjectContext];
	NSError *error = nil;
	NSArray *array = [moc executeFetchRequest:request error:&error];
	if (!array) {
		NSLog(@"Unable to execute fetch request %@: %@", request, [error localizedDescription]);
		return nil;
	}
	if ([array count] < 1) return nil;
	return [array objectAtIndex:0];
}




- (NSFetchRequest *)fetchRequestForEntityNamed:(NSString *)name {
	id moc = [self managedObjectContext];
	NSEntityDescription *ed = [NSEntityDescription entityForName:name inManagedObjectContext:moc];
	if (!ed) {
		NSLog(@"Unable to get entity description for entity named '%@'", ed);
		return nil;
	}
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:ed];
	return request;
}


- (void)deleteObject:(NSManagedObject *)object {
	[[self managedObjectContext] deleteObject:object];
}


@end
