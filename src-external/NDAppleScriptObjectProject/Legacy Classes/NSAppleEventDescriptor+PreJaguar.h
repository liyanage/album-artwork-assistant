/*
 *  NSAppleEventDescriptor+PreJaguar.h category
 *  NDAppleScriptObjectProject
 *
 *  Created by Nathan Day on Sat Feb 15 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@interface NSAppleEventDescriptor (PreJaguar)

+ (NSAppleEventDescriptor *)descriptorWithString:(NSString *)aString;
+ (NSAppleEventDescriptor *)descriptorWithBoolean:(BOOL)aValue

@end
