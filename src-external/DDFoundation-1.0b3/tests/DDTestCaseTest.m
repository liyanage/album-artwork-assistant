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

#import "DDTestCaseTest.h"


@implementation DDTestCaseTest

- (void) testPathForResource
{
    NSString * path = [self pathForResource: @"test" ofType: @"plist"];
    STAssertNotNil(path, nil);
}

- (void) testForNonExistantResource
{
    NSString * path = [self pathForResource: @"unknown" ofType: @"plist"];
    STAssertNil(path, nil);
}

- (void) testStringForResource
{
    NSString * actual = [self stringForResource: @"hello" ofType: @"txt"];
    NSString * expected = @"Hello!\n";
    STAssertEqualObjects(actual, expected, nil);
}

- (void) testDataForResource
{
    NSData * actual = [self dataForResource: @"hello" ofType: @"txt"];
    NSData * expected = [@"Hello!\n" dataUsingEncoding: NSUTF8StringEncoding];
    STAssertEqualObjects(actual, expected, nil);
}

- (void) testPlistForResource
{
    id plist = [self plistForResource: @"test"];
    STAssertNotNil(plist, nil);
    STAssertTrue([plist isKindOfClass: [NSDictionary class]], nil);

    NSDictionary * actual = plist;
    NSDictionary * expected = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"Foo", @"Name", nil];
    STAssertEqualObjects(actual, expected, nil);
}

@end
