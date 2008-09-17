//
//  FetchiTunesAlbumsScriptCommand.m
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 15.07.08.
//  Copyright 2008 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import "FetchiTunesAlbumsScriptCommand.h"


@implementation FetchiTunesAlbumsScriptCommand

- (id)performDefaultImplementation {
	[self performSelector:@selector(postNotification) withObject:nil afterDelay:0.2];
	return nil;
}


- (void)postNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"fetchiTunesAlbums" object:nil];
}

@end
