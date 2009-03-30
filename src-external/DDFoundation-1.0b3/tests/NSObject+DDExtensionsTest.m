//
//  NSObject+DDExtensionsTest.m
//  DDFoundation
//
//  Created by Dave Dribin on 5/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSObject+DDExtensionsTest.h"
#import "NSObject+DDExtensions.h"


@implementation NSObject_DDExtensionsTest

@synthesize done = _done;
@synthesize invoked = _invoked;

- (int)incrementByInt:(int)count
{
    _count += count;
    self.invoked = YES;
    return _count;
}

- (void)backgroundMethod:(NSNumber *)waitUntilDoneNumber
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    BOOL wait = [waitUntilDoneNumber boolValue];
    
    id grabber = 
        [self dd_invokeOnMainThreadAndWaitUntilDone:wait];
    [grabber incrementByInt:10];
    
    if (wait)
        [[grabber invocation] getReturnValue:&_result];
    
    self.done = YES;
    [pool release];
}

- (void)testForwardInvokesOnMainThreadWait
{
    _count = 0;
    _result = 0;
    self.done = NO;
    self.invoked = NO;
    
    [self performSelectorInBackground:@selector(backgroundMethod:)
                           withObject:[NSNumber numberWithBool:YES]];
    while (!self.done)
    {
        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                 beforeDate: [NSDate date]];
    }
    STAssertEquals(_count, 10, nil);
    STAssertEquals(_result, 10, nil);
}

- (void)testForwardInvokesOnMainThreadNoWait
{
    _count = 0;
    _result = 0;
    self.done = NO;
    self.invoked = NO;
    
    [self performSelectorInBackground:@selector(backgroundMethod:)
                           withObject:[NSNumber numberWithBool:NO]];
    while (!self.invoked)
    {
        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                 beforeDate: [NSDate date]];
    }
    STAssertEquals(_count, 10, nil);
}

- (void)mainThreadMethod:(NSNumber *)number;
{
    // If arguments were not retained, this will dereference a released
    // object, and cause a crash.
    _count = [number intValue];
    self.invoked = YES;
}

- (void)backgroundMethodWithObject
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSNumber * number = [NSNumber numberWithInt:42];
    
    [[self dd_invokeOnMainThreadAndWaitUntilDone:NO] mainThreadMethod:number];
    
    self.done = YES;
    [pool release];
}

- (void)testForwardNoWaitRetainsArguments
{
    _count = 0;
    _result = 0;
    self.done = NO;
    self.invoked = NO;
    
    [self performSelectorInBackground:@selector(backgroundMethodWithObject)
                           withObject:nil];
    while (!self.invoked)
    {
        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                 beforeDate: [NSDate date]];
    }
    STAssertEquals(_count, 42, nil);
}

@end
