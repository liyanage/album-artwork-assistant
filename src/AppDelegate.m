#import "AppDelegate.h"
#import "RegexKitLite.h"
#import "GTMNSDictionary+URLArguments.h"
#import "NSString+SBJSON.h"
#import "GoogleImageItem.h"
#import "UpdateOperation.h"
#import "NSObject+DDExtensions.h"

@implementation AppDelegate

@synthesize isBusy;
@synthesize isImageSelected;
@synthesize isQueueProcessing;
@synthesize busyMessage;
@synthesize queue;


# pragma mark IBActions

- (IBAction)showExampleAppleScript:(id)sender {

	NSString *path = [[NSBundle mainBundle] pathForResource:@"Example AppleScript" ofType:nil];
	[[NSWorkspace sharedWorkspace] openFile:path];

	NSLog(@"show example applescript %@", path);

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
}


- (IBAction)setAlbumTitle:(NSString *)newTitle {
	albumTitle = newTitle;
	[self findImages:self];
}


- (IBAction)setAlbumArtwork:(id)sender {
	[self performSelectorInBackground:@selector(setAlbumArtworkBackground:) withObject:sender];
}

- (void)setAlbumArtworkBackground:(id)sender {
	UpdateOperation *uo = [self makeUpdateOperation];
	if (!uo) return;
	[uo main];
}



- (IBAction)findImages:(id)sender {
	if ([albumTitle length] < 1) return;
	[self clearImages];
	[self startBusy:@"Searching Google Images"];
	[self performSelector:@selector(doFindImages:) withObject:self afterDelay:0.1];
}


- (void)prepareAlbumTrackName {
	[self willChangeValueForKey:@"searchSuggestions"];
	[self didChangeValueForKey:@"searchSuggestions"];
	NSArray *suggestions = [self searchSuggestions];
	[self setAlbumTitle:[suggestions objectAtIndex:0]];
}


- (void)clearImages {
	[images removeAllObjects];
}



# pragma mark iTunes query

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
	NSAssert(trackData, @"Unable to parse iTunes track list AppleScript");
//	NSLog(@"array: %@", trackData);
	[self setValue:trackData forKey:@"tracks"];
	return YES;
}



# pragma mark Google query


// Using the Google REST API
// http://code.google.com/apis/ajaxsearch/documentation/#fonje
// http://code.google.com/apis/ajaxsearch/documentation/reference.html#_fonje_image
//
// http://code.google.com/apis/ajaxsearch/signup.html
//
- (void)doFindImages:(id)sender {

	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	NSString *baseUrl = @"http://ajax.googleapis.com/ajax/services/search/images";
	[params setValue:albumTitle forKey:@"q"];
	[params setValue:@"off" forKey:@"safe"];
	[params setValue:@"small|medium|large|xlarge" forKey:@"imgsz"];
	[params setValue:@"1.0" forKey:@"v"];
	[params setValue:@"large" forKey:@"rsz"];
	[params setValue:@"ABQIAAAAt1bSH3Wmg2fvvnIb0y5uvhS0jwAaCC029fzyhtFJrJElrIqu7RRizOg1QMwXnj23EWMmFM6G-MNfyw" forKey:@"key"];

	for (int i = 0; i < GOOGLE_IMAGE_RESULT_PAGE_COUNT; i++) {
		[params setValue:[NSNumber numberWithInt:i * GOOGLE_IMAGE_RESULTS_PER_PAGE] forKey:@"start"];
		NSString *urlString = [NSString stringWithFormat:@"%@?%@", baseUrl, [params gtm_httpArgumentsString]];
//		urlString = @"file://localhost/Users/liyanage/svn/entropy/music-artwork/test/testdata.json";
		//NSLog(@"url: %@", urlString);

		NSURL *myUrl = [NSURL URLWithString:urlString];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:myUrl];
		[request setValue:@"http://www.entropy.ch/software/macosx/album-artwork-assistant/" forHTTPHeaderField:@"Referer"];
		NSURLResponse *response = nil;
		NSError *error = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if (error) {
			[window presentError:error modalForWindow:window delegate:self didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
			[self clearBusy];
			return;
		}

		id imageData = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] JSONValue];
		
		for (id item in [imageData valueForKeyPath:@"responseData.results"]) {
			[images addObject:[[GoogleImageItem alloc] initWithSearchResult:item]];
		}
	}

	[images sortUsingSelector:@selector(areaCompare:)];
	[imageBrowser reloadData];
	[self clearBusy];

}



# pragma mark update operation manipulation

- (UpdateOperation *)makeUpdateOperation {
	int index = [[imageBrowser selectionIndexes] firstIndex];
	GoogleImageItem *item = [images objectAtIndex:index];

	[self startBusy:@"Downloading selected image"];
	
	NSError *error = nil;
	NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[item url]] options:0 error:&error];
	[self clearBusy];

	if (error) {
		[self displayErrorWithTitle:@"Image not available" message:@"This image is not available, please try a different one"];
		NSLog(@"error for url '%@': %@", [item url], error);
		[images removeObjectAtIndex:index];
		[[imageBrowser dd_invokeOnMainThread] reloadData];
		return nil;
	}
	[item setImageData:imageData];
	UpdateOperation *uo = [[UpdateOperation alloc] initWithTracks:tracks imageItem:item statusDelegate:self];
	return uo;

}



# pragma mark queue manipulation

- (IBAction)addToQueue:(id)sender {
	[queueDrawer open];
	[self performSelectorInBackground:@selector(addToQueueBackground:) withObject:sender];
}

- (IBAction)addToQueueBackground:(id)sender {
	UpdateOperation *uo = [self makeUpdateOperation];
	if (!uo) return;
	[queueController addObject:uo];
}



- (IBAction)processQueue:(id)sender {
	if ([self isQueueProcessing]) {
		[self setIsQueueProcessing:NO];
		[self clearBusy];
		[processQueueButton setState:NSOffState];
		return;
	}

	[self setIsQueueProcessing:YES];
	[self setBusyMessage:@"Processing Queue"];
	[self performSelector:@selector(processOneQueueEntry) withObject:nil afterDelay:0.1];
}


- (void)processOneQueueEntry {
	if (!([self isQueueProcessing] && [queue count] > 0)) {
		[self setIsQueueProcessing:NO];
		[self clearBusy];
		[processQueueButton setState:NSOnState];
		return;
	}

	[self setBusyMessage:@"Processing Queue 2"];
	[[queue objectAtIndex:0] main];
    [self willChangeValueForKey:@"queue"];
	[queue removeObjectAtIndex:0];
    [self didChangeValueForKey:@"queue"];

	[self performSelector:@selector(processOneQueueEntry) withObject:nil afterDelay:0.1];
}



# pragma mark data binding methods

-(NSArray *)searchSuggestions {
	NSMutableArray *searchSuggestions = [NSMutableArray array];
	if (!tracks) return searchSuggestions;

	NSMutableString *firstAlbumTitle = [NSMutableString stringWithString:[[tracks objectAtIndex:0] valueForKey:@"trackalbum"]];
	[self cleanupString:firstAlbumTitle];
	[searchSuggestions addObject:firstAlbumTitle];

	NSString *firstArtist = [[tracks objectAtIndex:0] valueForKey:@"trackartist"];	NSMutableString *artist = [NSMutableString stringWithString:firstArtist];
	[self cleanupString:artist];
	[artist insertString:@" " atIndex:0];
	[artist insertString:firstAlbumTitle atIndex:0];
	[searchSuggestions addObject:artist];

	return searchSuggestions;
}


- (void)setSearchSuggestions:(id)searchlist {
	// this method is here so the search field can write back through the binding
	// even though we don't intend to store the search history list it gives us.
}


- (void)cleanupString:(NSMutableString *)input {
	[input replaceOccurrencesOfRegex:@"\\s*\\[.+\\]\\s*" withString:@""];
	[input replaceOccurrencesOfRegex:@"\\s*\\(.+\\)\\s*" withString:@""];
}





# pragma mark NSNibAwaking protocol methods

- (void)awakeFromNib {
	images = [NSMutableArray array];
	[self setQueue:[NSMutableArray array]];

	[self setupDefaults];
	[self setupNotifications];
}

# pragma mark setup methods

- (void)setupDefaults {
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:DOUBLECLICK_ACTION_QUEUE], @"doubleClickAction", nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}



- (void)setupNotifications {
	// the AppleScript command object sends this notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetch:) name:@"fetchiTunesAlbums" object:nil];
}


# pragma mark NSResponder presentError delegate methods

- (void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo {
}

# pragma mark StatusDelegateProtocol protocol methods

- (void)startBusy:(NSString *)message {
	[self setIsBusy:YES];
	[self setBusyMessage:message];
}

- (void)clearBusy {
	[self setIsBusy:NO];
	[self setBusyMessage:@""];
}


- (BOOL)displayErrorWithTitle:(NSString *)title message:(NSString *)message {
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:title, NSLocalizedDescriptionKey, message, NSLocalizedRecoverySuggestionErrorKey, nil];
	NSError *error = [NSError errorWithDomain:ERRORDOMAIN code:1 userInfo:userInfo];
	[[window dd_invokeOnMainThread] presentError:error modalForWindow:window delegate:self didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
	return NO;
}




# pragma mark image browser IKImageBrowserDataSource protocol methods

- (id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
	return [images objectAtIndex:index];
}

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
	return [images count];
}





# pragma mark image browser IKImageBrowserDelegate protocol methods

- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser {
	[self setIsImageSelected:[[aBrowser selectionIndexes] count] > 0];
}


- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index {
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"doubleClickAction"] == DOUBLECLICK_ACTION_QUEUE) {
		[self addToQueue:self];
	} else {
		[self setAlbumArtwork:self];
	}
}




@end
