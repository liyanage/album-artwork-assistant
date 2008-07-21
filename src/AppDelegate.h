#import <Cocoa/Cocoa.h>
#import "UpdateOperation.h"
#import "StatusDelegateProtocol.h"
#import "QuickLookImageBrowserView.h"

#define DOUBLECLICK_ACTION_QUEUE 1
#define GOOGLE_IMAGE_RESULT_PAGE_COUNT 2
#define GOOGLE_IMAGE_RESULTS_PER_PAGE 8
#define ERRORDOMAIN @"ch.entropy.album-artwork-assistant"

@interface AppDelegate : NSObject <StatusDelegateProtocol> {
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSWindow *window;
	IBOutlet NSDrawer *queueDrawer;
	IBOutlet NSButton *processQueueButton;
    IBOutlet QuickLookImageBrowserView *imageBrowser;
    IBOutlet NSArrayController *queueController;
	NSArray *tracks;
	NSString *albumTitle;
	NSMutableArray *images;
	BOOL isImageSelected;
	BOOL isQueueProcessing;
	BOOL isBusy;
	NSString *busyMessage;
	NSMutableArray *queue;
}

@property BOOL isBusy;
@property BOOL isImageSelected;
@property BOOL isQueueProcessing;
@property(assign) NSString *busyMessage;
@property(assign) NSMutableArray *queue;

- (IBAction)showExampleAppleScript:(id)sender;
- (IBAction)fetch:(id)sender;
- (IBAction)setAlbumArtwork:(id)sender;
- (IBAction)setAlbumTitle:(NSString *)albumTitle;
- (void)setAlbumArtworkBackground:(id)sender;
- (IBAction)addToQueue:(id)sender;
- (IBAction)addToQueueBackground:(id)sender;
- (BOOL)fetchITunesTrackList;
- (void)prepareAlbumTrackName;
- (void)clearImages;
- (IBAction)findImages:(id)sender;
- (void)doFindImages:(id)sender;
- (IBAction)processQueue:(id)sender;
- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser;
- (UpdateOperation *)makeUpdateOperation;
- (void)processOneQueueEntry;
- (NSArray *)searchSuggestions;
- (void)cleanupString:(NSMutableString *)input;
- (void)setupDefaults;
- (void)setupNotifications;

@end
