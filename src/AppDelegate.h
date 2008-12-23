#import <Cocoa/Cocoa.h>
#import "UpdateOperation.h"
#import "StatusDelegateProtocol.h"
#import "QuickLookImageBrowserView.h"
#import "IKImageBrowserFileUrlDataSource.h"
#import "DataStore.h"
#import "ImageSearchItem.h"
#import "TrackGroup.h"
#import <WebKit/WebKit.h>

#define DOUBLECLICK_ACTION_QUEUE 1
#define GOOGLE_IMAGE_RESULT_PAGE_COUNT 2
#define GOOGLE_IMAGE_RESULTS_PER_PAGE 8
#define ERRORDOMAIN @"ch.entropy.album-artwork-assistant"

@interface AppDelegate : NSObject <StatusDelegateProtocol, IKImageBrowserFileUrlDataSource> {
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSWindow *window;
	IBOutlet NSDrawer *queueDrawer;
	IBOutlet NSButton *processQueueButton;
    IBOutlet QuickLookImageBrowserView *imageBrowser;
    IBOutlet NSArrayController *queueController;
    IBOutlet NSArrayController *groupsController;
    IBOutlet NSTabView *tabView;
    IBOutlet WebView *webView;
    IBOutlet NSMenuItem *addImmediatelyMenuItem;
    IBOutlet NSMenuItem *addToQueueMenuItem;
	DOMHTMLElement *highlightedElement;
	NSString *highlightedElementOriginalStyle;
	NSArray *tracks;
	NSString *albumTitle;
	NSMutableArray *images;
	BOOL isImageSelected;
	BOOL isQueueProcessing;
	BOOL isBusy;
	NSString *statusMessage;
	NSMutableArray *queue;
	
	DataStore *dataStore;
}

@property BOOL isBusy;
@property BOOL isImageSelected;
@property BOOL isQueueProcessing;
@property(assign) NSString *statusMessage;
@property(assign) NSMutableArray *queue;
@property(assign) DataStore *dataStore;

- (IBAction)removeSelectedTrackGroups:(id)sender;
- (IBAction)installiTunesAppleScript:(id)sender;
- (BOOL)canInstalliTunesAppleScript;
- (BOOL)copyiTunesAppleScript:(NSError **)error;
- (BOOL)createiTunesShortcut;
- (BOOL)isImageSelectedAndImageBrowserTabActive;
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
- (void)doWebSearch:(id)sender;
- (void)doFindImages:(id)sender;
- (void)doFindImagesGoogle;
- (void)doFindImagesAmazon;
- (IBAction)processQueue:(id)sender;
- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser;
- (UpdateOperation *)makeUpdateOperationForImageData:(NSData *)imageData;
- (void)processOneQueueEntry;
- (NSArray *)searchSuggestions;
- (void)cleanupString:(NSMutableString *)input;
- (void)setupDefaults;
- (void)setupNotifications;
- (id)makeTrackGroupWithImageData:(NSData *)imageData;
- (NSUInteger)queueLength;
- (BOOL)isQueueEmpty;
- (void)switchToMainTab;

- (NSData *)imageDataForItem:(ImageSearchItem *)item;
- (void)removeItemAtIndex:(int)index;
- (ImageSearchItem *)selectedImage;
- (void)removeCurrentItemAndWarn;

- (IBAction)debug:(id)sender;

@end
