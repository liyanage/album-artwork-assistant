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

#import "DDInvocationGrabberTest.h"
#import "DDInvocationGrabber.h"


@implementation DDInvocationGrabberTest

- (void)testGrabbingValidMethod
{
    NSMutableString *theString = [NSMutableString stringWithString:@""];
    STAssertEqualObjects(theString, @"", @"Inital test data wasn't what we expected.");
    
    DDInvocationGrabber *theGrabber = [DDInvocationGrabber invocationGrabber];
    
    STAssertNotNil(theGrabber, @"Didn't create a grabber.");
    
    [[theGrabber prepareWithInvocationTarget:theString] appendString:@"Hello World"];
    
    STAssertEquals([theGrabber target], theString, @"Target of the grabber isn't what we expected.");
    
    [[theGrabber invocation] invoke];
    
    STAssertEqualObjects(theString, @"Hello World", @"Result of invoking didn't change the test data how we expected.");
}

- (void)testGrabbingInvalidMethod
{
    @try
	{
        NSMutableString *theString = [NSMutableString stringWithString:@""];
        DDInvocationGrabber *theGrabber = [DDInvocationGrabber invocationGrabber];
        [[theGrabber prepareWithInvocationTarget:theString] addObject:@"Hello World"];
        STAssertEquals([theGrabber target], theString, @"Target of the grabber isn't what we expected.");
        [[theGrabber invocation] invoke];
        
        STFail(@"We should have thrown an exception.");
	}
    @catch (NSException *localException)
	{
        // Expected
	}
}

@end
