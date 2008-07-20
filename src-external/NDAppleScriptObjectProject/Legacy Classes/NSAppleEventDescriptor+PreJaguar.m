/*
 *  NSAppleEventDescriptor+PreJaguar.m category
 *  NDAppleScriptObjectProject
 *
 *  Created by Nathan Day on Sat Feb 15 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NSAppleEventDescriptor+PreJaguar.h"


@implementation NSAppleEventDescriptor (PreJaguar)

/*
 * + appleEventDescriptorWithString:
 */
+ (NSAppleEventDescriptor *)descriptorWithString:(NSString *)aString
{
	return [self descriptorWithDescriptorType:typeChar data:[aString dataUsingEncoding:NSMacOSRomanStringEncoding]];
}

/*
 * + descriptorWithBoolean:
 */
+ (NSAppleEventDescriptor *)descriptorWithBoolean:(BOOL)aValue
{
	return [self descriptorWithDescriptorType:typeBoolean data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}

@end
