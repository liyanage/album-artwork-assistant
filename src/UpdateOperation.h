//
//  UpdateOperation.h
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 14.07.08.
//  Copyright 2008 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GoogleImageItem.h"
#import "StatusDelegateProtocol.h"

@interface UpdateOperation : NSOperation {
	id statusDelegate;
	NSArray *tracks;
	GoogleImageItem *imageItem;
	NSImage *albumImage;
}





//@property(assign) NSImage *albumImage;

- (id)initWithTracks:(NSArray *)tracks imageItem:(GoogleImageItem *)imageItem statusDelegate:(id <StatusDelegateProtocol>)statusDelegate;
- (NSString *)albumTitle;
- (NSImage *)tinyAlbumImage;

@end
