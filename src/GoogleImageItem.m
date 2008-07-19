//
//  GoogleImageItem.m
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 14.07.08.
//  Copyright 2008 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import "GoogleImageItem.h"
#import <Quartz/Quartz.h>

@implementation GoogleImageItem

@synthesize imageData;


- (id)initWithSearchResult:(NSDictionary *)sr {
	self = [super init];
	if (!self) return nil;
	searchResult = sr;
//	NSLog(@"init data: %@", sr);
	return self;
}


- (NSString *)imageUID {
	return [searchResult valueForKey:@"url"];
}


- (NSString *)imageRepresentationType {
	return IKImageBrowserNSURLRepresentationType;
}


- (id)imageRepresentation {
	return [NSURL URLWithString:[searchResult valueForKey:@"tbUrl"]];
}


- (NSString *)imageSubtitle {
	return [NSString stringWithFormat:@"%@x%@", [searchResult valueForKey:@"width"], [searchResult valueForKey:@"height"]];
}


- (unsigned int)area {
	return [[searchResult valueForKey:@"width"] intValue] * [[searchResult valueForKey:@"height"] intValue];
}


- (NSComparisonResult)areaCompare:(GoogleImageItem *)anItem {
	unsigned int a = [self area];
	unsigned int b = [anItem area];
	if (a == b) return NSOrderedSame;
	return b < a ? NSOrderedAscending : NSOrderedDescending;
}


- (NSString *)description {
	return [searchResult valueForKey:@"url"];
}


- (NSString *)url {
	return [searchResult valueForKey:@"url"];
}
	

- (NSImage *)tinyImage {
	// http://www.omnigroup.com/mailman/archive/macosx-dev/2001-November/033402.html
	NSImage *image = [[NSImage alloc] initWithData:imageData];
	NSImageRep *sourceImageRep = [image bestRepresentationForDevice:nil];
	NSImage *targetImage = [[NSImage alloc] initWithSize:NSMakeSize(28, 28)];
	[targetImage lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[sourceImageRep drawInRect:NSMakeRect(0, 0, 28, 28)];
	[targetImage unlockFocus];
	return targetImage;
}



@end


