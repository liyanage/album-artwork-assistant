#import <Cocoa/Cocoa.h>
#import "Quartz/Quartz.h"

@interface AppDelegate : NSObject {
	IBOutlet NSWindow *window;
    IBOutlet IKImageBrowserView *imageBrowser;
	NSArray *tracks;
	NSMutableString *albumTitle;
	NSMutableArray *images;
	BOOL isImageSelected;
	BOOL isBusy;
	NSString *busyMessage;
	NSOperationQueue *queue;
}

@property BOOL isBusy;
@property(assign) NSString *busyMessage;

- (IBAction)fetch:(id)sender;
- (IBAction)findImages:(id)sender;
- (IBAction)setAlbumArtwork:(id)sender;
- (IBAction)setAlbumArtworkBackground:(id)sender;
- (BOOL)fetchITunesTrackList;
- (BOOL)displayErrorWithTitle:(NSString *)title message:(NSString *)message;
- (void)prepareAlbumTrackName;
- (void)clearImages;
- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)startBusy:(NSString *)message;
- (void)clearBusy;

@end
