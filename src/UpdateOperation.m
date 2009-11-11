//
//  UpdateOperation.m
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 14.07.08.
//  Copyright 2008-2009 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import "UpdateOperation.h"
#import "GTMNSAppleScript+Handler.h"
#import "NSObject+DDExtensions.h"

@implementation UpdateOperation

@synthesize fileUrl;

- (id)initWithTracks:(NSArray *)t imageData:(NSData *)iData statusDelegate:(id <StatusDelegateProtocol>)sd {
	self = [super init];
	if (!self) return self;
	tracks = t;
	imageData = iData;
	statusDelegate = sd;
	didComplete = NO;
	return self;
}


- (void)main {

	@try {

		if (!self.fileUrl) {
			@throw [NSException exceptionWithName:@"TempFileWrite" reason:NSLocalizedString(@"cant_write_tempfile", @"") userInfo:nil];
		}
		
		NSString *tempFilePath = [self.fileUrl path];

		[statusDelegate startBusy:[NSString stringWithFormat:NSLocalizedString(@"adding_image_to_%@", @""), [self albumTitle]]];

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
		
		didComplete = YES;

	}
	
	@catch (NSException *e) {
		[statusDelegate displayErrorWithTitle:NSLocalizedString(@"cant_set_artwork", @"") message:[e reason]];
	}
	
	@finally {
		[statusDelegate clearBusy];
	}

}



- (BOOL)didComplete {
	return didComplete;
}



- (NSString *)albumTitle {
	return [[tracks objectAtIndex:0] valueForKey:@"track_album"];
}


- (NSURL *)fileUrl {
	if (fileUrl) return fileUrl;
	
	NSString *tempFilePath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), @"album-artwork-assistant.tmp"];

	if (![imageData writeToFile:tempFilePath atomically:YES]) {
		NSLog(@"Unable to store image data to temp file '%@'", tempFilePath);
		return nil;
	}
	[self setFileUrl:[NSURL fileURLWithPath:tempFilePath]];
	return fileUrl;
}








@end
