//
//  SignedAwsSearchRequest.m
//
//  Class to encapsulate the generation of a signed Amazon AWS search request URL.
//  Amazon started to require signed AWS requests in 2009. See these documents for
//  details about the signing mechanism:
//
//  http://docs.amazonwebservices.com/AWSECommerceService/latest/DG/index.html?RequestAuthenticationArticle.html
//  http://docs.amazonwebservices.com/AWSECommerceService/2008-06-26/DG/
//
//  Created as part of the Album Artwork Assistant Mac OS X application
//
//  Created by Marc Liyanage on 15.06.09.
//  Copyright 2009 Marc Liyanage <http://www.entropy.ch>.
// 
//  You are free to use this class if you give credit somewhere
//  in your application or documentation.
//

#import "SignedAwsSearchRequest.h"
#import "GTMNSString+URLArguments.h"
#import "GTMNSData+zlib.h"
#import "GTMBase64.h"

NSInteger stringByteSort(NSString *a, NSString *b, void *context);

@implementation SignedAwsSearchRequest

@synthesize accessKeyId, secretAccessKey;
@synthesize awsHost, awsPath;

- (id)initWithAccessKeyId:(NSString *)id secretAccessKey:(NSString *)key {
	if (self = [super init]) {
		self.accessKeyId = id;
		self.secretAccessKey = key;
		self.awsHost = @"ecs.amazonaws.com";
		self.awsPath = @"/onca/xml";
	}
	return self;
}


- (void)dealloc {
	[accessKeyId release];
	[secretAccessKey release];
	[awsHost release];
	[awsPath release];
	[super dealloc];
}


- (NSString *)searchUrlforKeywordsString:(NSString *)keywords {
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setValue:keywords                forKey:@"Keywords"];
	[params setValue:@"AWSECommerceService"  forKey:@"Service"];
	[params setValue:@"ItemSearch"           forKey:@"Operation"];
	[params setValue:self.accessKeyId        forKey:@"AWSAccessKeyId"];
	[params setValue:@"wwwentropych-20"      forKey:@"AssociateTag"];
	[params setValue:@"Music"                forKey:@"SearchIndex"];
	[params setValue:@"Images"               forKey:@"ResponseGroup"];
	[params setValue:@""                     forKey:@"DummyEmpty"];

	NSDateFormatter *outputFormatter = [[[NSDateFormatter alloc] init] autorelease];
	outputFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
	outputFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	NSString *timestamp = [outputFormatter stringFromDate:[NSDate date]];
	[params setValue:timestamp forKey:@"Timestamp"];
	
	NSArray *paramNames = [[params allKeys] sortedArrayUsingFunction:stringByteSort context:nil];
	NSMutableString *urlString = [NSMutableString string];
	int i, n = [paramNames count];
	for (i = 0; i < n; i++) {
		NSString *paramName = [paramNames objectAtIndex:i];
		[urlString appendFormat:@"%@=%@", paramName, [[params objectForKey:paramName] gtm_stringByEscapingForURLArgument]];
		if (i < n - 1) [urlString appendString:@"&"];
	}

	NSMutableString *signatureInput = [NSMutableString string];
	[signatureInput appendString:@"GET\n"];
	[signatureInput appendString:self.awsHost];
	[signatureInput appendString:@"\n"];
	[signatureInput appendString:self.awsPath];
	[signatureInput appendString:@"\n"];
	[signatureInput appendString:urlString];

	unsigned char *signatureInputBytes = (unsigned char *)[signatureInput UTF8String];
	
	unsigned char mac[SHA256_DIGEST_SIZE + 1];
	bzero(mac, SHA256_DIGEST_SIZE + 1);

	hmac_sha256((unsigned char *)[self.secretAccessKey UTF8String], [self.secretAccessKey length], signatureInputBytes, [signatureInput length], mac, SHA256_DIGEST_SIZE);
	mac[SHA256_DIGEST_SIZE] = 0;
	
	NSString *signature = [GTMBase64 stringByEncodingBytes:mac length:SHA256_DIGEST_SIZE];
	NSString *escapedSignature = [signature gtm_stringByEscapingForURLArgument];
	return [NSString stringWithFormat:@"http://%@%@?%@&Signature=%@", self.awsHost, self.awsPath, urlString, escapedSignature];
}


+ (NSString *)decodeKey:(char *)keyBytes length:(int)length {
	NSData *data = [NSData gtm_dataByInflatingBytes:keyBytes length:length];
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

@end


NSInteger stringByteSort(NSString *a, NSString *b, void *context) {
	return strcmp([a UTF8String], [b UTF8String]);
}

