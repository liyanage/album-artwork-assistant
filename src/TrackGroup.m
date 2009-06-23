// 
//  TrackGroup.m
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 18.08.08.
//  Copyright 2008-2009 Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import "TrackGroup.h"


@implementation TrackGroup 

@dynamic imageData;
@dynamic title;
@dynamic tracks;


// http://www.omnigroup.com/mailman/archive/macosx-dev/2001-November/033402.html
- (NSImage *)tinyAlbumImage {
	if (tinyAlbumImage) return tinyAlbumImage;
	NSImage *image = [[NSImage alloc] initWithData:self.imageData];
	NSImageRep *sourceImageRep = [image bestRepresentationForDevice:nil];
	NSImage *targetImage = [[NSImage alloc] initWithSize:NSMakeSize(28, 28)];
	[targetImage lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[sourceImageRep drawInRect:NSMakeRect(0, 0, 28, 28)];
	[targetImage unlockFocus];
	return tinyAlbumImage = targetImage;
}


- (NSArray *)tracksData {
	NSMutableArray *tracks = [NSMutableArray array];
	for (id track in self.tracks) {
		id trackData = [NSMutableDictionary dictionary];
		[trackData setValue:[track valueForKey:@"id"] forKey:@"trackid"];
		[trackData setValue:[track valueForKey:@"containerid"] forKey:@"trackcontainerid"];
		[trackData setValue:[track valueForKey:@"album"] forKey:@"trackalbum"];
		[tracks addObject:trackData];
	}
	return tracks;
}


@end
