//
//  GoogleImageItem.h
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 14.07.08.
//  Copyright 2008-2009 Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageSearchItem.h"

#define HTTP_SUCCESS 200

@interface ImageSearchItem : NSObject {
	NSDictionary *searchResult;
	NSData *imageData;
	NSURL *fileUrl;
	NSString *source;
}

@property(assign) NSData *imageData;
@property(assign) NSURL *fileUrl;
@property(assign) NSString *source;

- (id)initWithSearchResult:(NSDictionary *)searchResult;
- (NSComparisonResult)areaCompare:(ImageSearchItem *)anItem;
- (NSString *)url;
- (NSImage *)tinyImage;

- (NSString *)imageUID;
- (NSString *)imageRepresentationType;
- (id)imageRepresentation;
- (NSString *)imageSubtitle;
- (NSData *)dataError:(NSError **)error;

@end
