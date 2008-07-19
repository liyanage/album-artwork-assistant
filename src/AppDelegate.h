#import <Cocoa/Cocoa.h>
#import "Quartz/Quartz.h"
#import "UpdateOperation.h"
#import "StatusDelegateProtocol.h"

#define DOUBLECLICK_ACTION_QUEUE 1

@interface AppDelegate : NSObject <StatusDelegateProtocol> {
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSWindow *window;
	IBOutlet NSDrawer *queueDrawer;
	IBOutlet NSButton *processQueueButton;
    IBOutlet IKImageBrowserView *imageBrowser;
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

- (IBAction)fetch:(id)sender;
- (IBAction)setAlbumArtwork:(id)sender;
- (IBAction)setAlbumTitle:(NSString *)albumTitle;
- (IBAction)setAlbumArtworkBackground:(id)sender;
- (IBAction)addToQueue:(id)sender;
- (IBAction)addToQueueBackground:(id)sender;
- (BOOL)fetchITunesTrackList;
- (BOOL)displayErrorWithTitle:(NSString *)title message:(NSString *)message;
- (void)runErrorSheet:(NSArray *)data;
- (void)prepareAlbumTrackName;
- (void)clearImages;
- (IBAction)findImages:(id)sender;
- (IBAction)doFindImages:(id)sender;
- (IBAction)processQueue:(id)sender;
- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)startBusy:(NSString *)message;
- (void)clearBusy;
- (UpdateOperation *)makeUpdateOperation;
- (void)processOneQueueEntry;
- (NSArray *)searchSuggestions;
- (void)cleanupString:(NSMutableString *)input;

@end
