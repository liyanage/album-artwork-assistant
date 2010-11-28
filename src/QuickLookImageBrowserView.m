//
//  QuickLookImageBrowserView.m
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 22.07.08.
//

#import "QuickLookImageBrowserView.h"
#import "ImageSearchItem.h"
#import "StatusDelegateProtocol.h"
#import "IKImageBrowserFileUrlDataSource.h"


@implementation QuickLookImageBrowserView


- (void)keyDown:(NSEvent *)event {	
	NSString *chars = [event charactersIgnoringModifiers]; 
//	NSLog(@"chars: %@", chars);
	if([chars characterAtIndex:0] == ' ') {
		[self userDidPressSpaceInImageBrowserView:self];
	} else if ([chars characterAtIndex:0] == ' ') {
	
	} else {
		[super keyDown:event];
	}
}


#pragma mark QLPreviewPanelController protocol

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel
{
	return YES;
}


- (void)userDidPressSpaceInImageBrowserView:(id)aBrowser {
	if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
		[[QLPreviewPanel sharedPreviewPanel] orderOut:self];
	} else {
		[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:self];
	}
}


#pragma mark QLPreviewPanelDataSource protocol

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
	NSIndexSet *selected = [self selectionIndexes];
	if (![selected count])
		return nil;
	
	NSInteger firstIndex = [selected firstIndex];
	ImageSearchItem *item = [[self dataSource] imageBrowser:self itemAtIndex:firstIndex];
	[[self delegate] startBusy:NSLocalizedString(@"loading_image", @"")];
	return item;
}


- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
	NSIndexSet *selected = [self selectionIndexes];
	return [selected count] ? 1 : 0;
}

@end
