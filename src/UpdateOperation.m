//
//  UpdateOperation.m
//  Music Artwork
//
//  Created by Marc Liyanage on 14.07.08.
//  Copyright 2008 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import "UpdateOperation.h"
#import "GTMNSAppleScript+Handler.h"


@implementation UpdateOperation

- (id)initWithTracks:(NSArray *)t imageItem:(GoogleImageItem *)ii {
	self = [super init];
	if (!self) return self;
	tracks = t;
	imageItem = ii;
//	NSLog(@"update operation init thread: %@", [NSThread currentThread]);
//	NSLog(@"update operation init: %@", t);
	return self;
}



- (void)main {

	NSLog(@"update operation start : %@", self);

	NSData *imageData = [imageItem imageData];
	NSString *tempFilePath = [NSString stringWithFormat:@"%@/music-artwork.tmp", NSTemporaryDirectory()];
	NSError *error = nil;
	[imageData writeToFile:tempFilePath options:0 error:&error];
	if (error) {
		NSLog(@"error writing temp file '%@': %@", tempFilePath, error);
		return;
	}

	NSString *scptPath = [[NSBundle mainBundle] pathForResource:@"embed-artwork" ofType:@"scpt" inDirectory:@"Scripts"];
	NSURL *scptUrl = [NSURL fileURLWithPath:scptPath];

	NSDictionary *errorDict = nil;
	NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:scptUrl error:&errorDict];

	NSArray *params = [NSArray arrayWithObjects:tracks, tempFilePath, nil];
	[script gtm_executePositionalHandler:@"embedArtwork" parameters:params error:&errorDict];

	[[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:&error];

	if (errorDict) {
		NSLog(@"UpdateOperation error: %@", [errorDict valueForKey:NSAppleScriptErrorBriefMessage]);
		return;
	}

	NSLog(@"update operation end : %@", self);
}


- (NSString *)description {
	return [NSString stringWithFormat:@"[UpdateOperation %@]", [imageItem url]];
}

@end
