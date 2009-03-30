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

#import "NSString+DDExtensionsTest.h"
#import "NSString+DDExtensions.h"

@implementation NSString_DDExtensionsTest

- (void) testMimeTypeForExtensionFunction;
{
    STAssertEqualObjects(DDMimeTypeForExtension(@"png"), @"image/png", nil);
    STAssertEqualObjects(DDMimeTypeForExtension(@"zip"), @"application/zip", nil);
    STAssertEqualObjects(DDMimeTypeForExtension(@"txt"), @"text/plain", nil);
    STAssertEqualObjects(DDMimeTypeForExtension(@".unknown"), @"application/octet-stream", nil);
    STAssertEqualObjects(DDMimeTypeForExtension(@""), @"application/octet-stream", nil);
}

- (void) testPathMimeTypeCategory;
{
    STAssertEqualObjects([@"foo.png" dd_pathMimeType], @"image/png", nil);
    STAssertEqualObjects([@"foo.zip" dd_pathMimeType], @"application/zip", nil);
    STAssertEqualObjects([@"foo.txt" dd_pathMimeType], @"text/plain", nil);
    STAssertEqualObjects([@"foo.unknown" dd_pathMimeType], @"application/octet-stream", nil);
    STAssertEqualObjects([@"foo" dd_pathMimeType], @"application/octet-stream", nil);
}

- (void)testNSPointToStringWithTemp
{
    NSPoint point = NSMakePoint(5, 10);
    STAssertEqualObjects(DDToNString(point),
                         NSStringFromPoint(point),
                         nil);
}

- (void)testNSPointToString
{
    STAssertEqualObjects(DDToNString(NSMakePoint(5, 10)),
                         NSStringFromPoint(NSMakePoint(5, 10)),
                         nil);
}

- (void)testNSSizeToString
{
    STAssertEqualObjects(DDToNString(NSMakeSize(15, 20)),
                         NSStringFromSize(NSMakeSize(15, 20)),
                         nil);
}

- (void)testNSRectToString
{
    STAssertEqualObjects(DDToNString(NSMakeRect(5, 10, 15, 20)),
                         NSStringFromRect(NSMakeRect(5, 10, 15, 20)),
                         nil);
}

- (void)testClassToString
{
    STAssertEqualObjects(DDToNString([NSString class]),
                         NSStringFromClass([NSString class]),
                         nil);
}

- (void)testSelectorToString
{
    STAssertEqualObjects(DDToNString(@selector(init)),
                         NSStringFromSelector(@selector(init)),
                         nil);
}

- (void)testNSRangeToString
{
    STAssertEqualObjects(DDToNString(NSMakeRange(5, 10)),
                         NSStringFromRange(NSMakeRange(5, 10)),
                         nil);
}

- (void)testIdToString
{
    STAssertEqualObjects(DDToNString(@"foo"),
                         ddsprintf(@"%@", @"foo"),
                         nil);
}

- (void)testBOOLToString
{
    STAssertEqualObjects(DDToNString(YES),
                         DDNSStringFromBOOL(YES),
                         nil);
}

@end
