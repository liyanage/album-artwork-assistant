#import "AppDelegate.h"
#import "RegexKitLite.h"
#import "GTMNSDictionary+URLArguments.h"
#import "NSString+SBJSON.h"
#import "UpdateOperation.h"
#import "NSObject+DDExtensions.h"
#import "GTMScriptRunner.h"

#define ITUNES_APPLESCRIPT_TITLE @"Find with Album Artwork Assistant"
#define ITUNES_APPLESCRIPT_NAME @"Find with Album Artwork Assistant.scpt"

@implementation AppDelegate

@synthesize isBusy;
@synthesize isImageSelected;
@synthesize isQueueProcessing;
@synthesize busyMessage;
@synthesize queue;
@synthesize dataStore;


# pragma mark IBActions


- (IBAction)fetch:(id)sender {
	[self startBusy:@"Fetching Tracks from iTunes"];
	if (![self fetchITunesTrackList]) return;
	[self clearBusy];
	if ([tracks count] < 1) {
		[self displayErrorWithTitle:@"Nothing appropriate selected in iTunes" message:@"Please select tracks in your iTunes Library’s main “Music” section. They must be file tracks and have an album name."];
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
	[self startBusy:@"Searching Amazon/Google"];
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


- (IBAction)installiTunesAppleScript:(id)sender {
	
	NSError *error = nil;
	
	if (![self canInstalliTunesAppleScript]) {
		[self displayErrorWithTitle:@"Please quit iTunes and System Preferences" message:@"You need to quit iTunes and System Preferences to intall the iTunes AppleScript"];
		return;
	}

	if (![self copyiTunesAppleScript:&error]) {
		if (error) [window presentError:error];
		[self displayErrorWithTitle:@"Unable to install iTunes AppleScript" message:@"Unable to copy the iTunes AppleScript to your Library > iTunes > Scripts folder"];
		return;
	}

	if (![self createiTunesShortcut]) {
		[self displayErrorWithTitle:@"Unable to configure keyboard shortcut" message:@"Unable to assign the keyboard shortcut for the iTunes AppleScript. You can try to assign it manually in System Preferences > Keyboard & Mouse > Keyboard Shortcuts. See the application Help documentation for mor information."];
		return;
	}

	[self displayErrorWithTitle:@"iTunes AppleScript installed" message:@"The AppleScript was installed successfully. You’ll find it in iTunes’ script menu."];

}



# pragma mark iTunes AppleScript installation

- (BOOL)canInstalliTunesAppleScript {
	NSArray *blockingAppIdentifiers = [NSArray arrayWithObjects:@"com.apple.iTunes", @"com.apple.systempreferences", nil];
	for (id app in [[NSWorkspace sharedWorkspace] launchedApplications]) {
		if ([blockingAppIdentifiers containsObject:[app valueForKey:@"NSApplicationBundleIdentifier"]]) return NO;
	}
	return YES;
}


- (BOOL)copyiTunesAppleScript:(NSError **)error {
	
	NSString *scriptDir = [[[NSHomeDirectory()
        stringByAppendingPathComponent:@"Library"]
        stringByAppendingPathComponent:@"iTunes"]
        stringByAppendingPathComponent:@"Scripts"];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm createDirectoryAtPath:scriptDir withIntermediateDirectories:YES attributes:nil error:error]) return NO;

	NSString *source = [[[NSBundle mainBundle] pathForResource:@"Example AppleScript" ofType:nil] stringByAppendingPathComponent:ITUNES_APPLESCRIPT_NAME];
	NSString *dest = [scriptDir stringByAppendingPathComponent:ITUNES_APPLESCRIPT_NAME];

	if ([fm fileExistsAtPath:dest] && ![fm removeItemAtPath:dest error:error]) return NO;
	if (![fm copyItemAtPath:source toPath:dest error:error]) return NO;

	return YES;
}



- (BOOL)createiTunesShortcut {
	NSUserDefaults *ud = [[NSUserDefaults alloc] init];
	[ud addSuiteNamed:@"com.apple.iTunes"];
	NSDictionary *dict = [ud dictionaryForKey:@"NSUserKeyEquivalents"];
	if (!(dict && [dict valueForKey:ITUNES_APPLESCRIPT_TITLE])) {
		NSString *cmd = [NSString stringWithFormat:@"defaults write com.apple.iTunes NSUserKeyEquivalents -dict-add '%@' '@$F'", ITUNES_APPLESCRIPT_TITLE];
		NSString *result = [[GTMScriptRunner runner] run:cmd];
		NSLog(@"executed command: %@, result: %@", cmd, result);
		[ud synchronize];
	}

	ud = [[NSUserDefaults alloc] init];
	[ud addSuiteNamed:@"com.apple.universalaccess"];
	NSArray *list = [ud arrayForKey:@"com.apple.custommenu.apps"];
	if (!(list && [list containsObject:@"com.apple.iTunes"])) {
		NSString *cmd = @"defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add 'com.apple.iTunes'";
		NSString *result = [[GTMScriptRunner runner] run:cmd];
		NSLog(@"executed command: %@, result: %@", cmd, result);
		[ud synchronize];
	}

	return YES;
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
	[self setValue:trackData forKey:@"tracks"];
	return YES;
}



# pragma mark Google/Amazon image search

// Using the Google REST API
// http://code.google.com/apis/ajaxsearch/documentation/#fonje
// http://code.google.com/apis/ajaxsearch/documentation/reference.html#_fonje_image
//
// http://code.google.com/apis/ajaxsearch/signup.html
//
- (void)doFindImages:(id)sender {
	[self doFindImagesAmazon];
	[self doFindImagesGoogle];

	[images sortUsingSelector:@selector(areaCompare:)];
	[imageBrowser reloadData];
	[self clearBusy];
}


- (void)doFindImagesGoogle {
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	NSString *baseUrl = @"http://ajax.googleapis.com/ajax/services/search/images";
	[params setValue:albumTitle forKey:@"q"];
	[params setValue:@"moderate" forKey:@"safe"];
	[params setValue:@"small|medium|large|xlarge" forKey:@"imgsz"];
	[params setValue:@"1.0" forKey:@"v"];
	[params setValue:@"large" forKey:@"rsz"];
	[params setValue:@"ABQIAAAAt1bSH3Wmg2fvvnIb0y5uvhS0jwAaCC029fzyhtFJrJElrIqu7RRizOg1QMwXnj23EWMmFM6G-MNfyw" forKey:@"key"];

	for (int i = 0; i < GOOGLE_IMAGE_RESULT_PAGE_COUNT; i++) {
		[params setValue:[NSNumber numberWithInt:i * GOOGLE_IMAGE_RESULTS_PER_PAGE] forKey:@"start"];
		NSString *urlString = [NSString stringWithFormat:@"%@?%@", baseUrl, [params gtm_httpArgumentsString]];
#ifdef DEBUG_NONET
		NSLog(@"using dummy google data");
		urlString = @"file://localhost/Users/liyanage/svn/entropy/album-artwork-assistant/test/testdata.google.json";
#endif

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
			id io = [[ImageSearchItem alloc] initWithSearchResult:item];
			[io setSource:@"Google"];
			[images addObject:io];
		}
	}
}


// http://docs.amazonwebservices.com/AWSECommerceService/2008-06-26/DG/
- (void)doFindImagesAmazon {

	NSString *baseUrl = @"http://ecs.amazonaws.com/onca/xml";
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setValue:albumTitle              forKey:@"Keywords"];
	[params setValue:@"AWSECommerceService"  forKey:@"Service"];
	[params setValue:@"ItemSearch"           forKey:@"Operation"];
	[params setValue:@"0H7A2M1CNG984DR9NGR2" forKey:@"AWSAccessKeyId"];
	[params setValue:@"wwwentropych-20"      forKey:@"AssociateTag"];
	[params setValue:@"Music"                forKey:@"SearchIndex"];
	[params setValue:@"Images"               forKey:@"ResponseGroup"];


	NSString *urlString = [NSString stringWithFormat:@"%@?%@", baseUrl, [params gtm_httpArgumentsString]];

#ifdef DEBUG_NONET
	NSLog(@"using dummy amazon data");
	urlString = @"file://localhost/Users/liyanage/svn/entropy/album-artwork-assistant/test/testdata.amazon.xml";
#endif

	NSError *error = nil;
	NSURL *myUrl = [NSURL URLWithString:urlString];
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:myUrl
            options:(NSXMLNodePreserveWhitespace)
            error:&error];

	if (error) {
		[window presentError:error modalForWindow:window delegate:self didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
		[self clearBusy];
		return;
	}
	
	NSString *xsltPath = [[NSBundle mainBundle] pathForResource:@"amazon2plist" ofType:@"xslt"];
	NSURL *xsltUrl = [NSURL fileURLWithPath:xsltPath];
	NSXMLDocument *plistDoc = [xmlDoc objectByApplyingXSLTAtURL:xsltUrl arguments:nil error:&error];
	id imageData = [[plistDoc description] propertyList];


	for (id item in [imageData valueForKeyPath:@"results"]) {
			id io = [[ImageSearchItem alloc] initWithSearchResult:item];
			[io setSource:@"Amazon"];
			[images addObject:io];
	}

}


# pragma mark update operation manipulation

- (UpdateOperation *)makeUpdateOperation {
	ImageSearchItem *item = [self selectedImage];
	[self startBusy:@"Downloading selected image"];
	NSData *imageData = [self imageDataForItem:item];
	[self clearBusy];
	if (!imageData) return nil;

	UpdateOperation *uo = [[UpdateOperation alloc] initWithTracks:tracks imageData:imageData statusDelegate:self];
	return uo;
}


- (UpdateOperation *)makeUpdateOperationForTrackGroup:(TrackGroup *)group {
	return [[UpdateOperation alloc] initWithTracks:[group tracksData] imageData:[group imageData] statusDelegate:self];
}


- (ImageSearchItem *)selectedImage {
	int index = [[imageBrowser selectionIndexes] firstIndex];
	return [images objectAtIndex:index];
}


- (void)removeItemAtIndex:(int)index {
	[images removeObjectAtIndex:index];
	[[imageBrowser dd_invokeOnMainThread] reloadData];
}


- (NSData *)imageDataForItem:(ImageSearchItem *)item {
	NSError *error;
	NSData *imageData = [item dataError:&error];
	if (!imageData) {
		[self removeCurrentItemAndWarn];
	}
	return imageData;
}


- (NSURL *)fileUrlForItemAtIndex:(int)index {
	ImageSearchItem *item = [images objectAtIndex:index];
	NSURL *fileUrl = [item fileUrl];
	if (!fileUrl) {
		[self removeCurrentItemAndWarn];
	}
	return fileUrl;
}


- (void)removeCurrentItemAndWarn {
	int index = [[imageBrowser selectionIndexes] firstIndex];
	[self removeItemAtIndex:index];
	[self displayErrorWithTitle:@"Image not available" message:@"This image is not available, please try a different one"];
}




# pragma mark queue manipulation

- (IBAction)addToQueue:(id)sender {
	[queueDrawer open];
	[self performSelectorInBackground:@selector(addToQueueBackground:) withObject:sender];
}


- (IBAction)addToQueueBackground:(id)sender {
	[self makeTrackGroup];
}


- (id)makeTrackGroup {

	ImageSearchItem *item = [self selectedImage];
	[self startBusy:@"Downloading selected image"];
	NSData *imageData = [self imageDataForItem:item];
	[self clearBusy];
	if (!imageData) return nil;

	NSManagedObject *trackGroup = [NSEntityDescription
		insertNewObjectForEntityForName:@"TrackGroup"
		inManagedObjectContext:[dataStore managedObjectContext]];
	
	[trackGroup setValue:[[tracks objectAtIndex:0] valueForKey:@"trackalbum"] forKey:@"title"];
	[trackGroup setValue:imageData forKey:@"imageData"];

	NSMutableSet *groupTracks = [trackGroup mutableSetValueForKey:@"tracks"];

	for (id trackData in tracks) {
		NSManagedObject *aTrack = [NSEntityDescription
			insertNewObjectForEntityForName:@"Track"
			inManagedObjectContext:[dataStore managedObjectContext]];

		[aTrack setValue:[trackData valueForKey:@"trackid"] forKey:@"id"];
		[aTrack setValue:[trackData valueForKey:@"trackname"] forKey:@"name"];
		[aTrack setValue:[trackData valueForKey:@"tracknumber"] forKey:@"number"];
		[aTrack setValue:[trackData valueForKey:@"trackalbum"] forKey:@"album"];
		[aTrack setValue:[trackData valueForKey:@"trackartist"] forKey:@"artist"];
		[aTrack setValue:[trackData valueForKey:@"trackcontainerid"] forKey:@"containerid"];

		[groupTracks addObject:aTrack];
	}
	
	return trackGroup;
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
	if (!([self isQueueProcessing] && ![self isQueueEmpty])) {
		[self setIsQueueProcessing:NO];
		[self clearBusy];
		[processQueueButton setState:NSOnState];
		return;
	}

	id trackGroup = [dataStore firstEntityNamed:@"TrackGroup"];
	UpdateOperation *uo = [self makeUpdateOperationForTrackGroup:trackGroup];
	[uo main];
	if ([uo didComplete]) {
		[dataStore deleteObject:trackGroup];
	} else {
		[self setIsQueueProcessing:NO];
	}

	[self performSelector:@selector(processOneQueueEntry) withObject:nil afterDelay:0.1];
}



- (NSUInteger)queueLength {
	return [dataStore countForEntityNamed:@"TrackGroup"];
}


- (BOOL)isQueueEmpty {
	return [self queueLength] < 1;
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
	[self setDataStore:[[DataStore alloc] init]];

	[self setupDefaults];
	[self setupNotifications];

	// force a fetch to get the count
	// http://theocacao.com/document.page/305
	[groupsController fetchWithRequest:nil merge:NO error:nil];
	if ([[groupsController arrangedObjects] count] > 0) {
		[queueDrawer open];
	}

}


- (IBAction)debug:(id)sender {
}


# pragma mark setup methods

- (void)setupDefaults {
	id sortDesc = [NSArchiver archivedDataWithRootObject:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"number" ascending:YES]]];
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:DOUBLECLICK_ACTION_QUEUE], @"doubleClickAction",
		[NSNumber numberWithFloat:0.4], @"imageBrowserZoom",
		sortDesc, @"tracksSortDescriptors",
		nil];
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
	[imageBrowser selectionChange];
}


- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index {
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"doubleClickAction"] == DOUBLECLICK_ACTION_QUEUE) {
		[self addToQueue:self];
	} else {
		[self setAlbumArtwork:self];
	}
}


#pragma mark application delegate methods

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    int reply = NSTerminateNow;
	[dataStore cleanup];
	dataStore = nil;
	return reply;
}

#pragma mark tracks table view delegate methods

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	return NO;
}



@end
