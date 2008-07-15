#import "AppDelegate.h"
#import "RegexKitLite.h"
#import "GTMNSDictionary+URLArguments.h"
#import "NSString+SBJSON.h"
#import "GoogleImageItem.h"
#import "UpdateOperation.h"

@implementation AppDelegate

@synthesize isBusy;
@synthesize busyMessage;

- (void)awakeFromNib {
	images = [NSMutableArray array];
	queue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:1];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetch:) name:@"fetchiTunesAlbums" object:nil];
	
}


- (void)startBusy:(NSString *)message {
	[self setIsBusy:YES];
	[self setBusyMessage:message];
}

- (void)clearBusy {
	[self setIsBusy:NO];
	[self setBusyMessage:@""];
}

- (IBAction)fetch:(id)sender {
	[self startBusy:@"Fetching Tracks from iTunes"];
	if (![self fetchITunesTrackList]) return;
	[self clearBusy];
	if ([tracks count] < 1) {
		[self displayErrorWithTitle:@"Nothing selected" message:@"Please select some file tracks in your iTunes Library’s main “Music” section"];
		return;
	}
	[self prepareAlbumTrackName];

	[self startBusy:@"Searching Google Images"];
	[self performSelector:@selector(findImages:) withObject:self afterDelay:0.1];

}


- (BOOL)fetchITunesTrackList {
	NSString *scptPath = [[NSBundle mainBundle] pathForResource:@"fetch-selection-info" ofType:@"scpt" inDirectory:@"Scripts"];
	NSURL *scptUrl = [NSURL fileURLWithPath:scptPath];

	NSDictionary *errorDict = nil;
	NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:scptUrl error:&errorDict];
	NSAppleEventDescriptor *ds = [script executeAndReturnError:&errorDict];

	if (errorDict) {
		return [self displayErrorWithTitle:@"Error getting selected tracks from iTunes" message:[errorDict valueForKey:NSAppleScriptErrorBriefMessage]];
	}

	NSArray *trackData = [[ds stringValue] propertyList];
//	NSLog(@"array: %@", trackData);
	[self setValue:trackData forKey:@"tracks"];
	
	return YES;
}


- (void)prepareAlbumTrackName {
	NSMutableString *firstAlbumTitle = [NSMutableString stringWithString:[[tracks objectAtIndex:0] valueForKey:@"trackalbum"]];
	[firstAlbumTitle replaceOccurrencesOfRegex:@"\\s*\\[.+\\]\\s*" withString:@""];
	[firstAlbumTitle replaceOccurrencesOfRegex:@"\\s*\\(.+\\)\\s*" withString:@""];
	[self setValue:firstAlbumTitle forKey:@"albumTitle"];
}

- (void)clearImages {
	[images removeAllObjects];
}


// Using the Google REST API
// http://code.google.com/apis/ajaxsearch/documentation/#fonje
// http://code.google.com/apis/ajaxsearch/documentation/reference.html#_fonje_image
//
- (IBAction)findImages:(id)sender {
	[self clearImages];

	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	NSString *baseUrl = @"http://ajax.googleapis.com/ajax/services/search/images";
	[params setValue:albumTitle forKey:@"q"];
	[params setValue:@"off" forKey:@"safe"];
	[params setValue:@"small|medium|large|xlarge" forKey:@"imgsz"];
	[params setValue:@"1.0" forKey:@"v"];
	[params setValue:@"large" forKey:@"rsz"];
	[params setValue:@"ABQIAAAAt1bSH3Wmg2fvvnIb0y5uvhSVWVehin1_PEfOA-xXHB6WLH9lFRQTP__QPd0wSpz_UqQslcENKiZlpA" forKey:@"key"];

	for (int i = 0; i < 2; i++) {
		[params setValue:[NSNumber numberWithInt:i * 8] forKey:@"start"];
		NSString *urlString = [NSString stringWithFormat:@"%@?%@", baseUrl, [params gtm_httpArgumentsString]];
		urlString = @"file://localhost/Users/liyanage/Desktop/Music%20Artwork/test/testdata.json";
		//NSLog(@"url: %@", urlString);

		NSURL *myUrl = [NSURL URLWithString:urlString];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:myUrl];
		[request setValue:@"http://www.entropy.ch/software/macosx/musicartwork/" forHTTPHeaderField:@"Referer"];
		NSURLResponse *response = nil;
		NSError *error = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		id imageData = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] JSONValue];
		
		for (id item in [imageData valueForKeyPath:@"responseData.results"]) {
			[images addObject:[[GoogleImageItem alloc] initWithSearchResult:item]];
		}
	}

	
	[images sortUsingSelector:@selector(areaCompare:)];
	[imageBrowser reloadData];
	[self clearBusy];

}



- (BOOL)displayErrorWithTitle:(NSString *)title message:(NSString *)message {
	NSArray *data = [NSArray arrayWithObjects:title, message, nil];

	fixme: use regular call
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"errorMessage" object:data];
}


- (void)runErrorSheet:

	NSAlert *alert = [NSAlert alertWithMessageText:title defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:message];
		
	[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	
	return NO;
}


- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
	return [images count];
}


- (id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
	return [images objectAtIndex:index];
}


- (void) imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser {
	[self setValue:[NSNumber numberWithBool:[[aBrowser selectionIndexes] count] > 0] forKey:@"isImageSelected"];
}


- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index {
	[self setAlbumArtwork:self];
}


- (IBAction)setAlbumArtwork:(id)sender {
	[self performSelectorInBackground:@selector(setAlbumArtworkBackground:) withObject:sender];
}


- (IBAction)setAlbumArtworkBackground:(id)sender {

	int index = [[imageBrowser selectionIndexes] firstIndex];
	//NSLog(@"index: %d", index);
	
	GoogleImageItem *item = [images objectAtIndex:index];

	[self startBusy:@"Downloading selected image"];
	
	NSError *error = nil;
	NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[item url]] options:0 error:&error];
	[self clearBusy];

	// fixme: main thread
	if (error) {
		[self displayErrorWithTitle:@"Image not available" message:@"This image is not available, please try a different one"];

		NSLog(@"error for url '%@': %@", [item url], error);
		[images removeObjectAtIndex:index];
		[imageBrowser performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
		return;
	}
	[item setImageData:imageData];
	UpdateOperation *uo = [[UpdateOperation alloc] initWithTracks:tracks imageItem:item];
	[self startBusy:@"Embedding image into music files"];
	// AppleScript is not thread safe...
//	[queue addOperation:uo];
	[uo main];
	[self clearBusy];
}






- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
}




@end
