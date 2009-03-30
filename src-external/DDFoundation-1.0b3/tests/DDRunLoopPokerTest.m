//
//  DDRunLoopPokerTest.m
//  DDFoundation
//
//  Created by Dave Dribin on 9/20/08.
//  Copyright 2008 Bit Maki, Inc.. All rights reserved.
//

#import "DDRunLoopPokerTest.h"
#import "DDRunLoopPoker.h"
#import "libkern/OSAtomic.h"

@interface DDRunLoopPokerTest ()

- (void)runInBackgroundAndWait:(SEL)selector;
- (void)threadEntry:(NSString *)value;

@end

@implementation DDRunLoopPokerTest

- (void)testRunLoopDoesNotRunOnWithoutPoker
{
    [self runInBackgroundAndWait:@selector(bgTestRunLoopDoesNotRunOnWithoutPoker)];
}

- (void)bgTestRunLoopDoesNotRunOnWithoutPoker
{
    NSRunLoop * currentRunLoop = [NSRunLoop currentRunLoop];
    BOOL result = [currentRunLoop runMode:NSDefaultRunLoopMode
                               beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    STAssertFalse(result, nil);
}

- (void)testPokeRunLoopRunsWithPoker
{
    [self runInBackgroundAndWait:@selector(bgTestPokeRunLoopRunsWithPoker)];
}

- (void)bgTestPokeRunLoopRunsWithPoker
{
    NSRunLoop * currentRunLoop = [NSRunLoop currentRunLoop];
    _poker = [DDRunLoopPoker pokerWithRunLoop:currentRunLoop];
    
    NSDate * startDate = [NSDate date];
    BOOL result = [currentRunLoop runMode:NSDefaultRunLoopMode
                               beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.0]];
    STAssertTrue(result, nil);
    NSTimeInterval waitTime = [startDate timeIntervalSinceNow];
    STAssertEqualsWithAccuracy(waitTime, 0.0, 0.01, nil);
    
    [_poker dispose];
}

- (void)testPokeRunLoop
{
    [self runInBackgroundAndWait:@selector(bgTestPokeRunLoop)];
}

- (void)bgTestPokeRunLoop
{
    NSRunLoop * currentRunLoop = [NSRunLoop currentRunLoop];
    _poker = [DDRunLoopPoker pokerWithRunLoop:currentRunLoop];

    // Use a thread rather than performSelector:withObject:afterDelay: or
    // a timer just to be sure we don't add a source to the run loop
    [NSThread detachNewThreadSelector:@selector(pokeRunLoop)
                             toTarget:self
                           withObject:nil];
    
    NSDate * startDate = [NSDate date];
    BOOL result = [currentRunLoop runMode:NSDefaultRunLoopMode
                               beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    STAssertTrue(result, nil);
    NSTimeInterval waitTime = [startDate timeIntervalSinceNow];
    STAssertEqualsWithAccuracy(waitTime, 0.0, 0.1, nil);
    
    [_poker dispose];
}

- (void)pokeRunLoop
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    [_poker pokeRunLoop];
    [pool drain];
}

/**
 * Run tests in their own thread with their own pristine run loop to
 * make sure there are no input sources already on them.
 */
- (void)runInBackgroundAndWait:(SEL)selector
{
    _threadDone = NO;
    NSString * value = NSStringFromSelector(selector);
    NSThread * backgroundThread = [[NSThread alloc] initWithTarget:self
                                                          selector:@selector(threadEntry:)
                                                            object:value];
    [backgroundThread start];
    [backgroundThread autorelease];
    
    [_condition lock];
    while (!_threadDone)
    {
        [_condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
    }
    [_condition unlock];
}

- (void)threadEntry:(NSString *)value;
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    @try
    {
        SEL selector = NSSelectorFromString(value);
        [self performSelector:selector];
    }
    @catch (NSException * e)
    {
        STFail(@"Caught exception: %@", e);
    }
    @catch (...)
    {
        STFail(@"Caught unknown exception");
    }
    @finally
    {
        [_condition lock];
        _threadDone = YES;
        [_condition signal];
        [_condition unlock];
    }
    [pool drain];
}

@end
