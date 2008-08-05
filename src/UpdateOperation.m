//
//  UpdateOperation.m
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 14.07.08.
//  Copyright 2008 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import "UpdateOperation.h"
#import "GTMNSAppleScript+Handler.h"
#import "NSObject+DDExtensions.h"

@implementation UpdateOperation

- (id)initWithTracks:(NSArray *)t imageItem:(ImageSearchItem *)ii statusDelegate:(id <StatusDelegateProtocol>)sd {
	self = [super init];
	if (!self) return self;
	tracks = t;
	imageItem = ii;
	statusDelegate = sd;
	return self;
}


- (void)main {

	@try {

		NSURL *fileUrl = imageItem.fileUrl;
		
		if (!fileUrl) {
			@throw [NSException exceptionWithName:@"TempFileWrite" reason:@"Unable to write temp file" userInfo:nil];
		}
		
		NSString *tempFilePath = [fileUrl path];

		[statusDelegate startBusy:[NSString stringWithFormat:@"Adding image to “%@”", [self albumTitle]]];

		NSString *scptPath = [[NSBundle mainBundle] pathForResource:@"embed-artwork" ofType:@"scpt" inDirectory:@"Scripts"];
		NSURL *scptUrl = [NSURL fileURLWithPath:scptPath];
		NSDictionary *errorDict = nil;
		NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:scptUrl error:&errorDict];
		if (errorDict) {
			@throw [NSException exceptionWithName:@"AppleScriptLoad" reason:[errorDict valueForKey:NSAppleScriptErrorBriefMessage] userInfo:nil];
		}

		NSArray *params = [NSArray arrayWithObjects:tracks, tempFilePath, nil];
		[[script dd_invokeOnMainThreadAndWaitUntilDone:YES] gtm_executePositionalHandler:@"embedArtwork" parameters:params error:&errorDict];
		if (errorDict) {
			@throw [NSException exceptionWithName:@"AppleScriptExecute" reason:[errorDict valueForKey:NSAppleScriptErrorBriefMessage] userInfo:nil];
		}
	}
	
	@catch (NSException *e) {
		[statusDelegate displayErrorWithTitle:@"Unable to set album artwork" message:[e reason]];
	}
	
	@finally {
		[statusDelegate clearBusy];
	}

}



- (NSString *)albumTitle {
	return [[tracks objectAtIndex:0] valueForKey:@"trackalbum"];
}



- (NSImage *)tinyAlbumImage {
	if (albumImage) return albumImage;
	return albumImage = [imageItem tinyImage];
}



- (NSString *)description {
	return [NSString stringWithFormat:@"[UpdateOperation %@]", [imageItem url]];
}

@end
