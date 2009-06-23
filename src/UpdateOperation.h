//
//  UpdateOperation.h
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 14.07.08.
//  Copyright 2008-2009 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageSearchItem.h"
#import "StatusDelegateProtocol.h"

@interface UpdateOperation : NSOperation {
	id statusDelegate;
	NSArray *tracks;
	ImageSearchItem *imageItem;
	NSData *imageData;
	NSURL *fileUrl;
	BOOL didComplete;
}

@property(assign) NSURL *fileUrl;

- (id)initWithTracks:(NSArray *)tracks imageData:(NSData *)imageData statusDelegate:(id <StatusDelegateProtocol>)statusDelegate;
- (NSString *)albumTitle;
- (BOOL)didComplete;


@end
