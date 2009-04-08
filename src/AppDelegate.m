
#import "AppDelegate.h"
#import "RegexKitLite.h"
#import "GTMNSDictionary+URLArguments.h"
#import "NSString+SBJSON.h"
#import "UpdateOperation.h"
#import "NSObject+DDExtensions.h"
#import "GTMScriptRunner.h"
#import "UKCrashReporter.h"

#include <mach/task.h>

#define ITUNES_APPLESCRIPT_TITLE @"Find with Album Artwork Assistant"
#define ITUNES_APPLESCRIPT_NAME @"Find with Album Artwork Assistant.scpt"

@implementation AppDelegate

@synthesize isBusy;
@synthesize isImageSelected;
@synthesize isQueueProcessing;
@synthesize statusMessage;
@synthesize queue;
@synthesize dataStore;


# pragma mark IBActions


- (IBAction)fetch:(id)sender {
	[self switchToMainTab];
	[self startBusy:NSLocalizedString(@"fetching_itunes_tracks", @"")];
	if (![self fetchITunesTrackList]) return;
	[self clearBusy];
	if ([tracks count] < 1) {
		[self displayErrorWithTitle:NSLocalizedString(@"no_itunes_selection_title", @"") message:NSLocalizedString(@"no_itunes_selection", @"")];
		return;
	}
	[self prepareAlbumTrackName];
}


- (IBAction)setAlbumTitle:(NSString *)newTitle {
	[self switchToMainTab];
	albumTitle = newTitle;
	[self findImages:self];
}


- (IBAction)setAlbumArtwork:(id)sender {
	[self performSelectorInBackground:@selector(setAlbumArtworkBackground:) withObject:sender];
//	[self setAlbumArtworkBackground:sender];
}


- (void)setAlbumArtworkBackground:(id)sender {

	NSData *imageData;
	if ([sender isKindOfClass:[NSMenuItem class]] && [(NSMenuItem *)sender representedObject]) {
		NSMenuItem *item = sender;
		NSAssert([item representedObject], @"representedObject not nil");
		NSDictionary *searchResult = [NSDictionary dictionaryWithObject:[item representedObject] forKey:@"url"];
		id io = [[ImageSearchItem alloc] initWithSearchResult:searchResult];
		imageData = [io dataError:nil];
	} else {
		ImageSearchItem *item = [self selectedImage];
		if (!item) return;
		[self startBusy:NSLocalizedString(@"downloading_image", @"")];
		imageData = [self imageDataForItem:item];
		[self clearBusy];
	}
	if (!imageData) return;
	UpdateOperation *uo = [self makeUpdateOperationForImageData:imageData];
	if (!uo) return;
	[uo main];
}


- (IBAction)findImages:(id)sender {
	if ([albumTitle length] < 1) return;
	[self clearImages];
	[self startBusy:NSLocalizedString(@"searching_internet", @"")];
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
	// if we don't do this, file descriptors from HTTP connections pile up
	// and crash the application sooner or later
	[[NSGarbageCollector defaultCollector] collectExhaustively];
	[self logProcessSize];
}


// http://miknight.blogspot.com/2005/11/resident-set-size-in-mac-os-x.html
- (void)logProcessSize {
	struct task_basic_info t_info;
    mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT;
    task_t task = MACH_PORT_NULL;
	task_for_pid(current_task(), getpid(), &task);
    task_info(task, TASK_BASIC_INFO, (task_info_t)&t_info, &t_info_count);
	NSLog(@"Process size: resident: %dmb, virtual %dmb", t_info.resident_size / (1024*1024), t_info.virtual_size / (1024*1024*2));
}


- (IBAction)installiTunesAppleScript:(id)sender {
	
	NSError *error = nil;
	
	if (![self canInstalliTunesAppleScript]) {
		[self displayErrorWithTitle:NSLocalizedString(@"quit_blocking_apps_title", @"") message:NSLocalizedString(@"quit_blocking_apps", @"")];
		return;
	}

	if (![self copyiTunesAppleScript:&error]) {
		if (error) [window presentError:error];
		[self displayErrorWithTitle:NSLocalizedString(@"cant_install_applescript_title", @"") message:NSLocalizedString(@"cant_install_applescript", @"")];
		return;
	}

	if (![self createiTunesShortcut]) {
		[self displayErrorWithTitle:NSLocalizedString(@"cant_configure_shortcut_title", @"") message:NSLocalizedString(@"cant_configure_shortcut", @"")];
		return;
	}

	[self displayErrorWithTitle:NSLocalizedString(@"script_installation_confirmation_title", @"") message:NSLocalizedString(@"script_installation_confirmation", @"")];

}


- (IBAction)openApplicationWebsite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.entropy.ch/software/macosx/album-artwork-assistant/"]];
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
		return [self displayErrorWithTitle:NSLocalizedString(@"cant_get_itunes_tracks", @"") message:[errorDict valueForKey:NSAppleScriptErrorBriefMessage]];
	}

	NSArray *trackData = [[ds stringValue] propertyList];
	NSAssert(trackData, NSLocalizedString(@"cant_parse_itunes_tracks", @""));
	[self setValue:[trackData mutableCopy] forKey:@"tracks"];
	return YES;
}



# pragma mark Google/Amazon image and web search

- (void)doWebSearch:(id)sender {
	
}


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
	NSPoint top = NSMakePoint(0, [imageBrowser bounds].size.height);
	[imageBrowser scrollPoint:top];
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

	if ([albumTitle isEqualToString:@"__crash__"]) {
		NSLog(@"forcing crash...");
		char *x = nil;
		NSLog(@"foo %d", *x);
	}

	if ([albumTitle isEqualToString:@"__assert__"]) {
		NSLog(@"forcing assertion failure...");
		NSAssert(0, @"forced assert");
	}

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

- (UpdateOperation *)makeUpdateOperationForImageData:(NSData *)imageData {
	if (!imageData) return nil;
	UpdateOperation *uo = [[UpdateOperation alloc] initWithTracks:tracks imageData:imageData statusDelegate:self];
	return uo;
}


- (UpdateOperation *)makeUpdateOperationForTrackGroup:(TrackGroup *)group {
	return [[UpdateOperation alloc] initWithTracks:[group tracksData] imageData:[group imageData] statusDelegate:self];
}


- (ImageSearchItem *)selectedImage {
	NSUInteger index = [self selectedImageIndex];
	NSUInteger count = [images count];
	if (index > count - 1) {
		NSLog(@"[[imageBrowser selectionIndexes] firstIndex] is %d but image count is only %d", index, count);
		return nil;
	}
	return [images objectAtIndex:index];
}


- (void)removeItemAtIndex:(int)index {
	[images removeObjectAtIndex:index];
	[[imageBrowser dd_invokeOnMainThread] reloadData];
}


- (NSData *)imageDataForItem:(ImageSearchItem *)item {
	NSError *error = nil;
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
	NSUInteger index = [self selectedImageIndex];
	NSAssert2(index >= 0 && index < IMAGE_BROWSER_MAX_ITEMS, @"selectionIndexes firstIndex in valid range (0 <= %d < %d) ", index, IMAGE_BROWSER_MAX_ITEMS);
	[self removeItemAtIndex:index];
	[self displayErrorWithTitle:NSLocalizedString(@"image_unavailable_title", @"") message:NSLocalizedString(@"image_unavailable", @"")];
}


- (NSUInteger)selectedImageIndex {
	NSIndexSet *sel = [[imageBrowser dd_invokeOnMainThreadAndWaitUntilDone:YES] selectionIndexes];
	NSUInteger index = [[sel dd_invokeOnMainThreadAndWaitUntilDone:YES] firstIndex];
	NSLog(@"selected index: %d, sel: %@, imgbrowser: %@", index, sel, imageBrowser);
	return index;
}

# pragma mark track list manipulation

// enable delete: menu command only when something is selected in the album track list
- (BOOL)validateMenuItem:(NSMenuItem *)item {
	if ([item action] != @selector(delete:)) return YES;
	return [albumTracksController selectionIndex] != NSNotFound;
	
}

- (IBAction)delete:(id)sender {
	[albumTracksController remove:sender];
}


# pragma mark queue manipulation

- (IBAction)addToQueue:(id)sender {
	[queueDrawer open];
	[self performSelectorInBackground:@selector(addToQueueBackground:) withObject:sender];
//	[self addToQueueBackground:sender];
}


- (IBAction)addToQueueBackground:(id)sender {
	id trackGroup;
	if ([sender isKindOfClass:[NSMenuItem class]] && [(NSMenuItem *)sender representedObject]) {
		NSMenuItem *item = sender;
		NSDictionary *searchResult = [NSDictionary dictionaryWithObject:[item representedObject] forKey:@"url"];
		id io = [[ImageSearchItem alloc] initWithSearchResult:searchResult];
		NSData *data = [io dataError:nil];
		if (!data) return;
		trackGroup = [self makeTrackGroupWithImageData:data];
	} else {
		ImageSearchItem *item = [self selectedImage];
		if (!item) return;
		trackGroup = [self makeTrackGroupWithImageData:[self imageDataForItem:item]];
	}
	if (!trackGroup) return;
	[[dataStore dd_invokeOnMainThread] save];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"queueAddSwitchesToItunes"]) {
		[[NSWorkspace sharedWorkspace] launchApplication:@"iTunes"];
	}
}


- (id)makeTrackGroupWithImageData:(NSData *)imageData {
	[self startBusy:NSLocalizedString(@"downloading_image", @"")];
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
	[self setStatusMessage:NSLocalizedString(@"processing_queue", @"")];
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
		[dataStore save];
	} else {
		[self setIsQueueProcessing:NO];
	}

	[self performSelector:@selector(processOneQueueEntry) withObject:nil afterDelay:0.1];
}


- (IBAction)removeSelectedTrackGroups:(id)sender {
	[groupsController remove:sender];
	[dataStore save];
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
		[NSNumber numberWithBool:YES], @"terminateWithItunes",
		[NSNumber numberWithBool:YES], @"queueAddSwitchesToItunes",
		[NSNumber numberWithInt:5], @"imageDownloadTimeoutSeconds",
		[NSNumber numberWithFloat:0.4], @"imageBrowserZoom",
		sortDesc, @"tracksSortDescriptors",
		nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}


- (void)setupNotifications {
	// the AppleScript command object sends this notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetch:) name:@"fetchiTunesAlbums" object:nil];

	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationDidQuit:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
}


- (void)applicationDidQuit:(NSNotification *)notification {
	NSLog(@"app did quit: %@", notification);

	if (![[[notification userInfo] valueForKey:@"NSApplicationBundleIdentifier"] isEqualToString:@"com.apple.iTunes"]) return;
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"terminateWithItunes"]) return;

	NSLog(@"itunes quit, so we're quitting...");

	[[NSApplication sharedApplication] terminate:self];
}



# pragma mark NSResponder presentError delegate methods

- (void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo {
}


# pragma mark StatusDelegateProtocol protocol methods

- (void)startBusy:(NSString *)message {
	[self setIsBusy:YES];
	[self setStatusMessage:message];
}

- (void)clearBusy {
	[self setIsBusy:NO];
	[self setStatusMessage:@""];
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

//	NSLog(@"image browser selected index: index: %d", [[imageBrowser selectionIndexes] firstIndex]);

//	NSIndexSet *set = [NSIndexSet indexSetWithIndex:index];
//	NSLog(@"doubleclick before: index: %@, %@, %d", set, [imageBrowser selectionIndexes], [[imageBrowser selectionIndexes] firstIndex]);
//	[imageBrowser setSelectionIndexes:set byExtendingSelection:NO];
	
//	NSLog(@"doubleclick after: index: %@, %@, index imageBrowser %d, index parameter: %d", set, [imageBrowser selectionIndexes], [[imageBrowser selectionIndexes] firstIndex], index);

//	return;

	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"doubleClickAction"] == DOUBLECLICK_ACTION_QUEUE) {
		[self addToQueue:self];
	} else {
		[self setAlbumArtwork:self];
	}
}


#pragma mark application delegate methods

/*
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    int reply = NSTerminateNow;
	[dataStore cleanup];
	dataStore = nil;
	return reply;
}
*/

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	UKCrashReporterCheckForCrash();
/*
	struct rlimit limit;
	getrlimit(RLIMIT_NOFILE, &limit);
	NSLog(@"RLIMIT_NOFILE: %d", limit.rlim_cur);
*/	
}


#pragma mark tracks table view delegate methods

/*
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	return NO;
}
*/

#pragma tab view management and delegate methods

- (void)switchToMainTab {
	[tabView selectTabViewItemWithIdentifier:@"imageSearch"];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {

	if (!(albumTitle && [albumTitle length] > 0)) return;

	if ([[tabViewItem identifier] isEqualToString:@"webSearch"]) {
		NSMutableString *queryString = [[albumTitle stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] mutableCopy];
		[queryString replaceOccurrencesOfRegex:@"&" withString:@"%26"];
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/search?ie=UTF-8&q=%@", queryString]];
#ifdef DEBUG_NONET
		url = [NSURL URLWithString:@"file://localhost/Users/liyanage/svn/entropy/album-artwork-assistant/Resources/English.lproj/Album%20Artwork%20Assistant%20Help/Album%20Artwork%20Assistant%20Help.html"];
#endif
		NSURLRequest *searchRequest = [NSURLRequest requestWithURL:url];
//		NSLog(@"searchRequest: %@", searchRequest);
		[[webView mainFrame] loadRequest:searchRequest];
	} else {
	}

}


- (BOOL)isImageSelectedAndImageBrowserTabActive {
	return [[[tabView selectedTabViewItem] identifier] isEqualToString:@"imageSearch"] && [self isImageSelected];
}



#pragma mark WebView UIDelegate delegate methods

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags {

//	NSLog(@"ui delegate element: %@", elementInformation);

	DOMNode *node = [elementInformation valueForKey:@"WebElementDOMNode"];
	if (highlightedElement) {
		if ([highlightedElement isSameNode:node]) return;
		[highlightedElement setAttribute:@"style" value:highlightedElementOriginalStyle];
		highlightedElement = highlightedElementOriginalStyle = nil;
		[self setStatusMessage:@""];
	}
	if (!node) return;
	if (!([node nodeType] == 1 && [[node nodeName] isEqualToString:@"IMG"])) return;
//	NSLog(@"node %d: %@, highlighted: %@ ", [node nodeType], node, highlightedElement);
	DOMHTMLElement *img = (DOMHTMLElement *)node;
	highlightedElement = img;
	highlightedElementOriginalStyle = [img getAttribute:@"style"];
	NSString *highlightStyle = @"outline: red solid 2px; opacity: 0.5;";
	if (highlightedElementOriginalStyle && [highlightedElementOriginalStyle length] > 0) {
		[img setAttribute:@"style" value:[NSString stringWithFormat:@"%@; %@", highlightedElementOriginalStyle, highlightStyle]];
	} else {
		[img setAttribute:@"style" value:highlightStyle];
	}
	[self setStatusMessage:NSLocalizedString(@"webview_image_hover", @"")];
	
}


- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {

	NSURL *imageUrl = [element valueForKey:@"WebElementImageURL"];
	if (!imageUrl) return defaultMenuItems;

//	NSMutableArray *items = [[defaultMenuItems mutableCopy] autorelease];
	NSMutableArray *items = [NSMutableArray array];
	NSMenuItem *item;

	NSString *absoluteUrl = [imageUrl absoluteString];
	if (!absoluteUrl) {
		NSLog(@"absoluteString is nil for url %@", imageUrl);
		return defaultMenuItems;
	}
	
	item = [addToQueueMenuItem copy];
	[item setRepresentedObject:absoluteUrl];
	[items insertObject:item atIndex:0];

	item = [addImmediatelyMenuItem copy];
	[item setRepresentedObject:absoluteUrl];
	[items insertObject:item atIndex:0];

	return items;
}



// redirect popups to the same web view
- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request {
	return webView;
}


// instead of closing, return to the previous history location which was probably the opener
- (void)webViewClose:(WebView *)sender {
	[webView goBack];
}


// don't allow javascript to resize our window
- (void)webView:(WebView *)sender setFrame:(NSRect)frame {
}



@end
