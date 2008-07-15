//
//  UpdateOperation.h
//  Music Artwork
//
//  Created by Marc Liyanage on 14.07.08.
//  Copyright 2008 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GoogleImageItem.h"

@interface UpdateOperation : NSOperation {
	NSArray *tracks;
	GoogleImageItem *imageItem;
}

- (id)initWithTracks:(NSArray *)tracks imageItem:(GoogleImageItem *)imageItem;

@end
