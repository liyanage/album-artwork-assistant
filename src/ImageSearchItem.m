//
//  GoogleImageItem.m
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 14.07.08.
//  Copyright 2008-2009 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import "ImageSearchItem.h"
#import <Quartz/Quartz.h>

@implementation ImageSearchItem

@synthesize imageData;
@synthesize fileUrl;
@synthesize source;


- (id)initWithSearchResult:(NSDictionary *)sr {
	self = [super init];
	if (!self) return nil;
	searchResult = sr;
	return self;
}



- (unsigned int)area {
	return [[searchResult valueForKey:@"width"] intValue] * [[searchResult valueForKey:@"height"] intValue];
}


- (NSComparisonResult)areaCompare:(ImageSearchItem *)anItem {
	unsigned int a = [self area];
	unsigned int b = [anItem area];
	return a == b ? NSOrderedSame : b < a ? NSOrderedAscending : NSOrderedDescending;
}


- (NSString *)description {
	return [NSString stringWithFormat:@"%@ %@", [super description], [searchResult valueForKey:@"url"]];
//	return [searchResult valueForKey:@"url"];
}


- (NSString *)url {
	return [searchResult valueForKey:@"url"];
}
	

- (NSImage *)tinyImage {
	// http://www.omnigroup.com/mailman/archive/macosx-dev/2001-November/033402.html
	NSImage *image = [[NSImage alloc] initWithData:imageData];
	NSImageRep *sourceImageRep = [[image representations] lastObject];
	NSImage *targetImage = [[NSImage alloc] initWithSize:NSMakeSize(28, 28)];
	[targetImage lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[sourceImageRep drawInRect:NSMakeRect(0, 0, 28, 28)];
	[targetImage unlockFocus];
	return targetImage;
}

#pragma mark IKImageBrowserItem protocol methods

- (NSString *)imageUID {
	return [searchResult valueForKey:@"url"];
}



- (NSString *)imageRepresentationType {
	return IKImageBrowserNSDataRepresentationType;
}


- (id)imageRepresentation {
	return [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[searchResult valueForKey:@"tbUrl"]]];
}


/*
- (NSString *)imageRepresentationType {
	return IKImageBrowserNSImageRepresentationType;
}


- (id)imageRepresentation {
	return [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[searchResult valueForKey:@"tbUrl"]]];
}
*/


/*
- (NSString *)imageRepresentationType {
	return IKImageBrowserNSURLRepresentationType;
}


- (id)imageRepresentation {
	return [NSURL URLWithString:[searchResult valueForKey:@"tbUrl"]];
}
*/

- (NSString *)imageSubtitle {
	return [NSString stringWithFormat:@"%@x%@ %@",
		[searchResult valueForKey:@"width"],
		[searchResult valueForKey:@"height"],
		[self source]
	];
}



#pragma mark data loader methods

- (NSData *)dataError:(NSError **)error {

	NSData *data = self.imageData;
	if (!data) {
		NSTimeInterval timeout = [[NSUserDefaults standardUserDefaults] floatForKey:@"imageDownloadTimeoutSeconds"];
		NSURL *imageURL = [NSURL URLWithString:[self url]];
		
		NSURLRequest *req = [NSURLRequest
			requestWithURL:imageURL
			cachePolicy:NSURLRequestUseProtocolCachePolicy
			timeoutInterval:timeout];
		NSURLResponse *response = nil;
		data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:error];
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
		if (data && ([imageURL isFileURL] || [httpResponse statusCode] == HTTP_SUCCESS)) {
			self.imageData = data;
		} else {
			NSLog(@"Unable to load image data from url '%@', error: %@", [self url], error ? *error : nil);
			data = nil;
		}
	}
	return data;
}


- (NSURL *)fileUrl {
	if (fileUrl) return fileUrl;
	
	NSString *tempFilePath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), [[self url] lastPathComponent]];
	NSError *error = nil;
	NSData *data = [self dataError:&error];
	if (!data) return nil;
	if (![data writeToFile:tempFilePath atomically:YES]) {
		NSLog(@"Unable to store image data to temp file '%@'", tempFilePath);
		return nil;
	}
	[self setFileUrl:[NSURL fileURLWithPath:tempFilePath]];
	return fileUrl;
}



#pragma mark QLPreviewItem protocol

- (NSURL *)previewItemURL
{
	NSURL *url = [self fileUrl];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SearchItemDidFinish" object:self];
	return url;
}



@end


