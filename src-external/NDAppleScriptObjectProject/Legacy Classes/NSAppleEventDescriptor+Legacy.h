/*
 *  NSAppleEventDescriptor+Legacy.h category
 *  NDAppleScriptObjectProject
 *
 *  Created by Nathan Day on Sat Feb 15 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"

@interface NSAppleEventDescriptor (Legacy)

+ (NSAppleEventDescriptor *)appleEventDescriptorWithString:(NSString *)aString;

+ (NSAppleEventDescriptor *)aliasListDescriptorWithArray:(NSArray *)aArray;

+ (NSAppleEventDescriptor *)appleEventDescriptorWithURL:(NSURL *)aURL;
+ (NSAppleEventDescriptor *)aliasDescriptorWithURL:(NSURL *)aURL;

+ (NSAppleEventDescriptor *)appleEventDescriptorWithBOOL:(BOOL)aValue;
+ (NSAppleEventDescriptor *)trueBoolDescriptor;
+ (NSAppleEventDescriptor *)falseBoolDescriptor;
+ (NSAppleEventDescriptor *)appleEventDescriptorWithShort:(short int)aValue;
+ (NSAppleEventDescriptor *)appleEventDescriptorWithLong:(long int)aValue;
+ (NSAppleEventDescriptor *)appleEventDescriptorWithInt:(int)aValue;
+ (NSAppleEventDescriptor *)appleEventDescriptorWithFloat:(float)aValue;
+ (NSAppleEventDescriptor *)appleEventDescriptorWithDouble:(double)aValue;
+ (NSAppleEventDescriptor *)appleEventDescriptorWithUnsignedInt:(unsigned int)aValue;

@end

@interface NDAppleScriptObject
- (NSAppleEventDescriptor *)targetNoProcess;
@end