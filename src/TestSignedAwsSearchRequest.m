//
//  TestSignedAwsSearchRequest.m
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 15.06.09.
//  Copyright 2009 Marc Liyanage <http://www.entropy.ch>. All rights reserved.
//

#import "TestSignedAwsSearchRequest.h"
#import "SignedAwsSearchRequest.h"
#import "amazon_aws_secret_key.h"


@implementation TestSignedAwsSearchRequest

- (void) testUrlGeneration
{
	char keyBytes[] = AMAZON_AWS_SECRET_KEY_BYTES;
	NSString *secretKey = [SignedAwsSearchRequest decodeKey:keyBytes length:AMAZON_AWS_SECRET_KEY_LENGTH];
    SignedAwsSearchRequest *req = [[[SignedAwsSearchRequest alloc] initWithAccessKeyId:@"0H7A2M1CNG984DR9NGR2" secretAccessKey:secretKey] autorelease];

	req.associateTag = @"wwwentropych-20";

	STAssertNotNil(req, @"not nil");
	STAssertEqualObjects(req.accessKeyId, @"0H7A2M1CNG984DR9NGR2", @"property value match");
	STAssertEqualObjects(req.awsHost, @"ecs.amazonaws.com", @"property value match");

	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setValue:@"ItemSearch"           forKey:@"Operation"];
	[params setValue:@"Music"                forKey:@"SearchIndex"];
	[params setValue:@"Images"               forKey:@"ResponseGroup"];
	[params setValue:@"amélie"               forKey:@"Keywords"];
	
	NSString *urlString = [req searchUrlForParameterDictionary:params];
	STAssertNotNil(urlString, @"search url not nil");
//	NSLog(@"request URL: %@", urlString);

	NSError *error = nil;
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:urlString] options:0 error:&error] autorelease];
	STAssertNotNil(doc, @"failed to load url %@: %@", urlString, error);
	
}   

- (void)testDecodeKey {
	char keyBytes[] = AMAZON_AWS_SECRET_KEY_BYTES;
	NSString *secretKey = [SignedAwsSearchRequest decodeKey:keyBytes length:AMAZON_AWS_SECRET_KEY_LENGTH];
	NSLog(@"key: %@, %d", secretKey, [secretKey length]);
} 


@end
