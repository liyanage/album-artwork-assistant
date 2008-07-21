//
//  GoogleImageItem.h
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 14.07.08.
//  Copyright 2008 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GoogleImageItem : NSObject {
	NSDictionary *searchResult;
	NSData *imageData;
}

@property(assign) NSData *imageData;

- (id)initWithSearchResult:(NSDictionary *)searchResult;
- (NSComparisonResult)areaCompare:(GoogleImageItem *)anItem;
- (NSString *)url;
- (NSImage *)tinyImage;

- (NSString *)imageUID;
- (NSString *)imageRepresentationType;
- (id)imageRepresentation;
- (NSString *)imageSubtitle;

@end
