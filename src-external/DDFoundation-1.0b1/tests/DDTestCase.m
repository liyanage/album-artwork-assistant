/*
 * Copyright (c) 2007-2008 Dave Dribin
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "DDTestCase.h"
#import "JRLog.h"

@implementation DDTestCase

+ (void) initialize;
{
    [self setDefaultJRLogLevel: JRLogLevel_Error];
}

- (NSString *) resourcePath;
{
    NSBundle * myBundle = [NSBundle bundleForClass: [self class]];
    return [myBundle resourcePath];
}

- (NSString *) pathForResource: (NSString *) resource ofType: (NSString *) type;
{
    NSBundle * myBundle = [NSBundle bundleForClass: [self class]];
    return [myBundle pathForResource: resource ofType: type];
}

- (NSString *) stringForResource: (NSString *) resource ofType: (NSString *) type;
{
    NSString * path = [self pathForResource: resource ofType: type];
    NSString * string = [NSString stringWithContentsOfFile: path
                                              usedEncoding: nil
                                                     error: nil];
    return string;
}

- (NSData *) dataForResource: (NSString *) resource ofType: (NSString *) type;
{
    NSString * path = [self pathForResource: resource ofType: type];
    NSData * data = [NSData dataWithContentsOfFile: path];
    return data;
}

- (id) plistForResource: (NSString *) resource;
{
    NSString * path = [self pathForResource: resource ofType: @"plist"];
    STAssertNotNil(path, nil);
    NSData * data = [NSData dataWithContentsOfFile: path];
    NSString * errorString = nil;
    id plist =
    [NSPropertyListSerialization propertyListFromData: data
                                     mutabilityOption: NSPropertyListMutableContainersAndLeaves
                                               format: nil
                                     errorDescription: &errorString];
    STAssertNil(errorString, errorString);
    return plist;
}

@end
