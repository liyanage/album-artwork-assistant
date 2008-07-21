//
//  QuickLookImageBrowserView.m
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 22.07.08.
//

// Info and code taken from
// http://www.macresearch.org/cocoa-tutorial-image-kit-cover-flow-and-quicklook-doing-things-we-shouldnt-are-too-fun-resist
// http://ciaranwal.sh/2007/12/07/quick-look-apis


#import "QuickLookImageBrowserView.h"
#import "QuickLook.h"
#import "GoogleImageItem.h"
#import "StatusDelegateProtocol.h"

@implementation QuickLookImageBrowserView

- (void)awakeFromNib {
	[self setupQuickLook];
}

- (void)setupQuickLook {
	if(![[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/QuickLookUI.framework"] load]) {
		NSLog(@"Unable to load Quick Look");
		return;
	}

	quickLookPanelClass = NSClassFromString(@"QLPreviewPanel");
//	NSLog(@"Quick Look loaded");
}



- (void)keyDown:(NSEvent *)event {	
	if([[event charactersIgnoringModifiers] characterAtIndex:0] == ' ') {
		[self userDidPressSpaceInImageBrowserView:self];
	} else {
		[super keyDown:event];
	}
}


- (void)userDidPressSpaceInImageBrowserView:(id)aBrowser {
	if (!quickLookPanelClass) return;
	// If the user presses space when the preview panel is open then we close it
	if([[quickLookPanelClass sharedPreviewPanel] isOpen])
		[[quickLookPanelClass sharedPreviewPanel] closeWithEffect:2];
	else {
		[self updateQuicklook];
	}
}


- (void)updateQuicklook {
	// Otherwise, set the current items
	NSIndexSet *selected = [self selectionIndexes];
	if (![selected count]) return;
	int index = [selected firstIndex];
	[self quickLookSelectedItems:index];

	NSMutableArray* URLs = [NSMutableArray array];
	[[quickLookPanelClass sharedPreviewPanel] setURLs:URLs currentIndex:0 preservingDisplayState:YES];
	
	// And then display the panel
	[[quickLookPanelClass sharedPreviewPanel] makeKeyAndOrderFrontWithEffect:2];
	
	// Restore the focus to our window to demo the selection changing, scrolling 
	// (left/right) and closing (space) functionality
	[[self window] makeKeyWindow];
}


- (void)quickLookSelectedItems:(int)itemIndex {

	GoogleImageItem *item = [[self dataSource] imageBrowser:self itemAtIndex:itemIndex];
	[[self delegate] startBusy:@"Loading Image"];
	[self performSelector:@selector(quickLookSelectedItems2:) withObject:[item url] afterDelay:0.1];
}


// todo: decouple from delegate, centralize object removal
// keep nsdata for image in googleimage object

- (void)quickLookSelectedItems2:(NSString *)urlString {
	NSURL *url = [NSURL URLWithString:urlString];
	NSData *data = [NSData dataWithContentsOfURL:url];
	[[self delegate] clearBusy];

	if (!data) {
		NSLog(@"unable to load image from %@", url);
		[[quickLookPanelClass sharedPreviewPanel] close];
		int index = [[self selectionIndexes] firstIndex];
		// formalize this
		[[[self delegate] valueForKey:@"images"] removeObjectAtIndex:index];
		[self reloadData];
		return;
	}

	NSString *tempFilePath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), [urlString lastPathComponent]];

	[data writeToFile:tempFilePath atomically:YES];
	url = [NSURL fileURLWithPath:tempFilePath];
	NSMutableArray* URLs = [NSMutableArray arrayWithCapacity:1];
	
	NSLog(@"ql url: %@", url);
	[URLs addObject:url];
	[[quickLookPanelClass sharedPreviewPanel] setURLs:URLs currentIndex:0 preservingDisplayState:YES];

}



















@end
