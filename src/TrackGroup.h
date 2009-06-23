//
//  TrackGroup.h
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 18.08.08.
//  Copyright 2008-2009 Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface TrackGroup : NSManagedObject  
{
	NSImage *tinyAlbumImage;
}

@property (retain) NSData *imageData;
@property (retain) NSString *title;
@property (retain) NSSet *tracks;

@end

@interface TrackGroup (CoreDataGeneratedAccessors)
- (void)addTracksObject:(NSManagedObject *)value;
- (void)removeTracksObject:(NSManagedObject *)value;
- (void)addTracks:(NSSet *)value;
- (void)removeTracks:(NSSet *)value;
- (NSImage *)tinyAlbumImage;
- (NSArray *)tracksData;
@end

