//
//  QuickLookImageBrowserView.h
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 22.07.08.
//  Copyright 2008-2009 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Quartz/Quartz.h"

@interface QuickLookImageBrowserView : IKImageBrowserView {
	Class quickLookPanelClass;
}

- (void)userDidPressSpaceInImageBrowserView:(id)aBrowser;
- (void)setupQuickLook;
- (void)updateQuickLook;
- (void)closeQuickLook;
- (void)quickLookSelectedItems:(int)itemIndex;
- (void)setQuickLookPanelDelegate:(id)delegate;
- (void)selectionChange;

@end
