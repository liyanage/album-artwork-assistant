//
//  SignedAwsSearchRequest.h
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 15.06.09.
//  Copyright 2009 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "hmac_sha2.h"

@interface SignedAwsSearchRequest : NSObject {
	NSString *accessKeyId, *secretAccessKey;
	NSString *awsHost, *awsPath;
}

@property (retain) NSString *accessKeyId, *secretAccessKey;
@property (retain) NSString *awsHost, *awsPath;

- (id)initWithAccessKeyId:(NSString *)accessKeyId secretAccessKey:(NSString *)secretAccessKey;
- (NSString *)searchUrlforKeywordsString:(NSString *)keywords;
+ (NSString *)decodeKey:(char *)keyBytes length:(int)length;


@end

