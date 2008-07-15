//
//  FetchiTunesAlbumsScriptCommand.m
//  Music Artwork
//
//  Created by Marc Liyanage on 15.07.08.
//  Copyright 2008 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import "FetchiTunesAlbumsScriptCommand.h"


@implementation FetchiTunesAlbumsScriptCommand

- (id)performDefaultImplementation {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"fetchiTunesAlbums" object:nil];
	return nil;
}

@end
