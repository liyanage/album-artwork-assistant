/*
 *  NSAppleEventDescriptor+Legacy.m category
 *  NDAppleScriptObjectProject
 *
 *  Created by Nathan Day on Sat Feb 15 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NSAppleEventDescriptor+Legacy.h"


@implementation NSAppleEventDescriptor (Legacy)

+ (NSAppleEventDescriptor *)appleEventDescriptorWithString:(NSString *)aString
{
	return [self descriptorWithString:aString];
}

+ (NSAppleEventDescriptor *)aliasListDescriptorWithArray:(NSArray *)aArray
{
	return [self descriptorWithArray:aArray];
}


+ (NSAppleEventDescriptor *)appleEventDescriptorWithURL:(NSURL *)aURL
{
	return [self descriptorWithURL:aURL];
}


+ (NSAppleEventDescriptor *)appleEventDescriptorWithBOOL:(BOOL)aValue
{
	return [self descriptorWithBoolean:aValue];
}

+ (NSAppleEventDescriptor *)trueBoolDescriptor
{
	return [self descriptorWithTrueBoolean];
}
+ (NSAppleEventDescriptor *)falseBoolDescriptor
{
	return [self descriptorWithFalseBoolean];
}
+ (NSAppleEventDescriptor *)trueBoolDescriptor
{
	return [self descriptorWithBoolean:YES];
}

+ (NSAppleEventDescriptor *)falseBoolDescriptor
{
	return [self descriptorWithBoolean:NO];
}

+ (NSAppleEventDescriptor *)appleEventDescriptorWithShort:(short int)aValue
{
	return [self descriptorWithShort:aValue];
}

+ (NSAppleEventDescriptor *)appleEventDescriptorWithLong:(long int)aValue
{
	return [self descriptorWithLong:aValue];
}

+ (NSAppleEventDescriptor *)appleEventDescriptorWithInt:(int)aValue
{
	return [self descriptorWithInt:aValue];
}

+ (NSAppleEventDescriptor *)appleEventDescriptorWithFloat:(float)aValue
{
	return [self descriptorWithFloat:aValue];
}

+ (NSAppleEventDescriptor *)appleEventDescriptorWithDouble:(double)aValue
{
	return [self descriptorWithDouble:aValue];
}

+ (NSAppleEventDescriptor *)appleEventDescriptorWithUnsignedInt:(unsigned int)aValue
{
	return [self descriptorWithUnsignedInt:aValue];
}

@end

@interface NDAppleScriptObject
- (NSAppleEventDescriptor *)targetNoProcess
{
	return [self AppleScriptAsAppleEventTarget];
}
@end