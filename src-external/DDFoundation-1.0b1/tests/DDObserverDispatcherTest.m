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

#import "DDObserverDispatcherTest.h"
#import "DDObserverDispatcher.h"


@interface DDObserverDispatcher (DDObserverDispatcherTest)

- (NSMutableDictionary *) test_keyPathsByObject;

@end

@implementation DDObserverDispatcher (Test)

- (NSMutableDictionary *) test_keyPathsByObject;
{
    return _keyPathsByObject;
}

@end


@interface DDObserverDispatcherTestObject : NSObject
{
    BOOL _flagged;
    BOOL _flagged2;
}

+ (id) object;
+ (NSThread *) backgroundThread;

- (BOOL) isFlagged;
- (void) setFlagged: (BOOL) flagged;
- (void) toggleFlagged;
- (void) toggleFlaggedInBackground;

- (BOOL) isFlagged2;
- (void) setFlagged2: (BOOL) flagged2;
- (void) toggleFlagged2;


@end

@implementation DDObserverDispatcherTestObject

static NSString * BACKGROUND_THREAD_NAME = @"Background Thread";

+ (id) object
{
    return [[[self alloc] init] autorelease];
}

+ (NSThread *) backgroundThread;
{
    static NSThread * sBackgroundThread = nil;
    if (sBackgroundThread == nil)
    {
        sBackgroundThread = [[NSThread alloc] initWithTarget: self
                                                    selector: @selector(backgroundEntry)
                                                      object: nil];
        [sBackgroundThread setName: BACKGROUND_THREAD_NAME];
        [sBackgroundThread start];
    }
    return sBackgroundThread;
}

+ (void) backgroundEntry
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    while (![[NSThread currentThread] isCancelled])
    {
        [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
    }
    [pool drain];
}

- (BOOL) isFlagged { return _flagged; }
- (void) setFlagged: (BOOL) flagged; { _flagged = flagged; }
- (void) toggleFlagged; { [self setFlagged: !_flagged]; }

- (void) toggleFlaggedInBackground;
{
    [self performSelector: @selector(toggleFlagged)
                 onThread: [[self class] backgroundThread]
               withObject: nil waitUntilDone: YES];
}

- (BOOL) isFlagged2 { return _flagged2; }
- (void) setFlagged2: (BOOL) flagged2; { _flagged2 = flagged2; }
- (void) toggleFlagged2; { [self setFlagged2: !_flagged2]; }

@end

@interface DDObserverDispatcherTestObserver : NSObject
{
    int _notificationCount;
    NSString * _lastThreadName;
}

@property(readwrite, copy) NSString * lastThreadName;

+ (id) observer;

- (void) countNotification: (NSNotification *) note;
- (void) ignoreNotification: (NSNotification *) note;
- (int) notificationCount;

@end

@implementation DDObserverDispatcherTestObserver : NSObject

@synthesize lastThreadName = _lastThreadName;

+ (id) observer;
{
    return [[[self alloc] init] autorelease];
}

- (void) dealloc;
{
    [_lastThreadName release];
    [super dealloc];
}

- (void) countNotification: (NSNotification *) note;
{
    _notificationCount++;
    self.lastThreadName = [NSThread currentThread].name;
}

- (void) ignoreNotification: (NSNotification *) note;
{
}

- (int) notificationCount;
{
    return _notificationCount;
}

@end

@implementation DDObserverDispatcherTest

- (id) dispatcherWithTarget: (id) target;
{
    return [[[DDObserverDispatcher alloc] initWithTarget: target] autorelease];
}

- (id) dispatcherWithTarget: (id) target dispatchOption: (DDObserverDispatchOption) dispatchOption;
{
    return [[[DDObserverDispatcher alloc] initWithTarget: target
                                   defaultDispatchOption: dispatchOption] autorelease];
}

- (void) testSimpleSetAction
{
    DDObserverDispatcherTestObject * object = [DDObserverDispatcherTestObject object];
    DDObserverDispatcherTestObserver * observer = [DDObserverDispatcherTestObserver observer];
    
    [object toggleFlagged];
    STAssertEquals([observer notificationCount], 0, nil);
    
    DDObserverDispatcher * dispatcher = [self dispatcherWithTarget: observer];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged" ofObject: object];
    
    [object toggleFlagged];
    [object toggleFlagged2];
    
    STAssertEquals([observer notificationCount], 1, nil);
    
    [dispatcher removeDispatchActionForKeyPath: @"flagged" ofObject: object];
    [object toggleFlagged];
    [object toggleFlagged2];
    STAssertEquals([observer notificationCount], 1, nil);

    NSMutableDictionary * keyPathsByObject = [dispatcher test_keyPathsByObject];
    STAssertEquals([keyPathsByObject count], 0U, nil);
}

- (void) testMultipleActions
{
    DDObserverDispatcherTestObject * object = [DDObserverDispatcherTestObject object];
    DDObserverDispatcherTestObserver * observer = [DDObserverDispatcherTestObserver observer];
    
    [object toggleFlagged];
    STAssertEquals([observer notificationCount], 0, nil);
    
    DDObserverDispatcher * dispatcher = [self dispatcherWithTarget: observer];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged" ofObject: object];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged2" ofObject: object];
    
    [object toggleFlagged];
    [object toggleFlagged2];
    
    STAssertEquals([observer notificationCount], 2, nil);
    
    [dispatcher removeDispatchActionForKeyPath: @"flagged" ofObject: object];
    [object toggleFlagged];
    [object toggleFlagged2];
    STAssertEquals([observer notificationCount], 3, nil);
    
    [dispatcher removeDispatchActionForKeyPath: @"flagged2" ofObject: object];
    [object toggleFlagged];
    [object toggleFlagged2];
    STAssertEquals([observer notificationCount], 3, nil);
    
    NSMutableDictionary * keyPathsByObject = [dispatcher test_keyPathsByObject];
    STAssertEquals([keyPathsByObject count], 0U, nil);
}

- (void) testResettingAction;
{
    DDObserverDispatcherTestObject * object = [DDObserverDispatcherTestObject object];
    DDObserverDispatcherTestObserver * observer = [DDObserverDispatcherTestObserver observer];
    
    [object toggleFlagged];
    STAssertEquals([observer notificationCount], 0, nil);
    
    DDObserverDispatcher * dispatcher = [self dispatcherWithTarget: observer];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged" ofObject: object];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged2" ofObject: object];
    
    [object toggleFlagged];
    [object toggleFlagged2];

    STAssertEquals([observer notificationCount], 2, nil);
    
    [dispatcher setDispatchAction: @selector(ignoreNotification:)
                       forKeyPath: @"flagged" ofObject: object];
    [object toggleFlagged];
    [object toggleFlagged2];
    STAssertEquals([observer notificationCount], 3, nil);
    
    [dispatcher removeDispatchActionForKeyPath: @"flagged2" ofObject: object];
    [object toggleFlagged];
    [object toggleFlagged2];
    STAssertEquals([observer notificationCount], 3, nil);
    
    [dispatcher removeDispatchActionForKeyPath: @"flagged" ofObject: object];
    [object toggleFlagged];
    [object toggleFlagged2];
    STAssertEquals([observer notificationCount], 3, nil);
}

- (void) testRemoveAllActions
{
    DDObserverDispatcherTestObject * object = [DDObserverDispatcherTestObject object];
    DDObserverDispatcherTestObserver * observer = [DDObserverDispatcherTestObserver observer];
    
    [object toggleFlagged];
    STAssertEquals([observer notificationCount], 0, nil);
    
    DDObserverDispatcher * dispatcher = [self dispatcherWithTarget: observer];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged" ofObject: object];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged2" ofObject: object];
    
    [object toggleFlagged];
    [object toggleFlagged2];
    
    STAssertEquals([observer notificationCount], 2, nil);
    
    [dispatcher removeAllDispatchActions];
    [object toggleFlagged];
    [object toggleFlagged2];
    STAssertEquals([observer notificationCount], 2, nil);
    
    NSMutableDictionary * keyPathsByObject = [dispatcher test_keyPathsByObject];
    STAssertEquals([keyPathsByObject count], 0U, nil);
}

- (void) testRemoveAllActionsForAnObserver
{
    DDObserverDispatcherTestObject * object1 = [DDObserverDispatcherTestObject object];
    DDObserverDispatcherTestObject * object2 = [DDObserverDispatcherTestObject object];
    DDObserverDispatcherTestObserver * observer = [DDObserverDispatcherTestObserver observer];
    
    DDObserverDispatcher * dispatcher = [self dispatcherWithTarget: observer];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged" ofObject: object1];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged2" ofObject: object1];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged" ofObject: object2];
    
    [object1 toggleFlagged];
    [object1 toggleFlagged2];
    [object2 toggleFlagged];
    
    STAssertEquals([observer notificationCount], 3, nil);
    
    [dispatcher removeAllDispatchActionsOfObject: object1];
    [object1 toggleFlagged];
    [object1 toggleFlagged2];
    [object2 toggleFlagged];
    STAssertEquals([observer notificationCount], 4, nil);
    
    NSMutableDictionary * keyPathsByObject = [dispatcher test_keyPathsByObject];
    STAssertEquals([keyPathsByObject count], 1U, nil);
    
    [dispatcher removeAllDispatchActionsOfObject: object2];
    [object1 toggleFlagged];
    [object1 toggleFlagged2];
    [object2 toggleFlagged];
    STAssertEquals([observer notificationCount], 4, nil);
    
    keyPathsByObject = [dispatcher test_keyPathsByObject];
    STAssertEquals([keyPathsByObject count], 0U, nil);
}

- (void) testBackgroundThreadName
{
    NSString * currentThreadName = [[NSThread currentThread] name];
    NSString * backgroundThreadName = [[DDObserverDispatcherTestObject backgroundThread] name];
    STAssertTrue(![currentThreadName isEqualToString: backgroundThreadName], nil);
}

- (void) testDefaultThreadOption
{
    DDObserverDispatcherTestObject * object = [DDObserverDispatcherTestObject object];
    DDObserverDispatcherTestObserver * observer = [DDObserverDispatcherTestObserver observer];
    
    DDObserverDispatcher * dispatcher = [self dispatcherWithTarget: observer];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged" ofObject: object];
    
    [object toggleFlaggedInBackground];
    STAssertEqualObjects(observer.lastThreadName, BACKGROUND_THREAD_NAME, nil);
}

- (void) testMainThreadOption
{
    DDObserverDispatcherTestObject * object = [DDObserverDispatcherTestObject object];
    DDObserverDispatcherTestObserver * observer = [DDObserverDispatcherTestObserver observer];
    
    DDObserverDispatcher * dispatcher = [self dispatcherWithTarget: observer
                                                    dispatchOption: DDObserverDispatchOnMainThread];
    [dispatcher setDispatchAction: @selector(countNotification:)
                       forKeyPath: @"flagged" ofObject: object];
    
    [object toggleFlaggedInBackground];
    STAssertEqualObjects(observer.lastThreadName, [[NSThread currentThread] name], nil);
}

@end
