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

#import "DDTemporaryDirectoryTest.h"
#import "DDTemporaryDirectory.h"

@implementation DDTemporaryDirectoryTest

- (void) testTemporaryDirectory;
{
    DDTemporaryDirectory * directory = [DDTemporaryDirectory temporaryDirectory];
    STAssertNotNil(directory, nil);
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSString * fullPath = [directory fullPath];
    STAssertNotNil([directory fullPath], nil);
    
    BOOL isDirectory = NO;
    STAssertTrue([fileManager fileExistsAtPath: fullPath isDirectory: &isDirectory],
                  nil);
    STAssertTrue(isDirectory, nil);
    
    NSString * tempFile = [fullPath stringByAppendingPathComponent: @"foo"];
    STAssertTrue([fileManager createFileAtPath: tempFile
                                      contents: [NSData data]
                                    attributes: nil],
                 nil);
    
    STAssertTrue([fileManager fileExistsAtPath: tempFile isDirectory: &isDirectory],
                 nil);
    STAssertFalse(isDirectory, nil);

    [directory cleanup];
    STAssertFalse([fileManager fileExistsAtPath: tempFile isDirectory: nil],
                  nil);
    STAssertFalse([fileManager fileExistsAtPath: fullPath isDirectory: nil],
                  nil);
}

@end
