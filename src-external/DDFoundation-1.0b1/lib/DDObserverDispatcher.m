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

#import "DDObserverDispatcher.h"

@interface DDObserverDispatcherEntry : NSObject
{
    SEL _action;
    BOOL _hasDispatchOption;
    DDObserverDispatchOption _dispatchOption;
}

+ (id) entryWithAction: (SEL) action;

+ (id) entryWithAction: (SEL) action
        dispatchOption: (DDObserverDispatchOption) dispatchOption;

- (id) initWithAction: (SEL) action;

- (id) initWithAction: (SEL) action
       dispatchOption: (DDObserverDispatchOption) dispatchOption;

- (SEL) action;

- (BOOL) hasDispatchOption;

- (DDObserverDispatchOption) dispatchOption;

@end

NSString * DDObserverDispatcherKeyPathKey = @"keyPath";
NSString * DDObserverDispatcherObjectKey = @"object";
NSString * DDObserverDispatcherChangeKey = @"change";

@implementation DDObserverDispatcherEntry

+ (id) entryWithAction: (SEL) action;
{
    id o =[[self alloc] initWithAction: action];
    return [o autorelease];
}

+ (id) entryWithAction: (SEL) action
        dispatchOption: (DDObserverDispatchOption) dispatchOption;
{
    id o =[[self alloc] initWithAction: action dispatchOption: dispatchOption];
    return [o autorelease];
}

- (id) initWithAction: (SEL) action;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _action = action;
    _hasDispatchOption = NO;
    
    return self;
}

- (id) initWithAction: (SEL) action
       dispatchOption: (DDObserverDispatchOption) dispatchOption;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _action = action;
    _hasDispatchOption = YES;
    _dispatchOption = dispatchOption;
    
    return self;
}

- (SEL) action;
{
    return _action;
}

- (BOOL) hasDispatchOption;
{
    return _hasDispatchOption;
}

- (DDObserverDispatchOption) dispatchOption;
{
    return _dispatchOption;
}

@end

@interface DDObserverDispatcher (Private)

- (void) removeObserverForAllKeyPaths: (NSMutableDictionary *) keyPaths
                      ofObjectWrapper: (NSArray *) objectWrapper;

- (void) setDispatchEntry: (DDObserverDispatcherEntry *) entry
               forKeyPath: (NSString *) keyPath
                 ofObject: (NSObject *) object;

@end

@implementation DDObserverDispatcher

- (id) initWithTarget: (id) target
defaultDispatchOption: (DDObserverDispatchOption) dispatchOption;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _target = target;
    _keyPathsByObject = [[NSMutableDictionary alloc] init];
    _defaultDispatchOption = dispatchOption;
    
    return self;
}

- (id) initWithTarget: (id) target;
{
    return [self initWithTarget: target
          defaultDispatchOption: DDObserverDispatchOnCallingThread];
}

- (id) init;
{
    return [self initWithTarget: nil];
}

- (void) dealloc
{
    [self removeAllDispatchActions];
    [_keyPathsByObject release];
    _keyPathsByObject = nil;
    
    [super dealloc];
}

- (void) finalize
{
    [self removeAllDispatchActions];
    [super finalize];
}

- (void) setDispatchAction: (SEL) action
                forKeyPath: (NSString *) keyPath
                  ofObject: (NSObject *) object;
{
    DDObserverDispatcherEntry * entry =
    [DDObserverDispatcherEntry entryWithAction: action];
    [self setDispatchEntry: entry
                forKeyPath: keyPath
                  ofObject: object];
}

- (void) setDispatchAction: (SEL) action
                forKeyPath: (NSString *) keyPath
                  ofObject: (NSObject *) object
            dispatchOption: (DDObserverDispatchOption) dispatchOption;
{
    DDObserverDispatcherEntry * entry =
    [DDObserverDispatcherEntry entryWithAction: action
                                dispatchOption: dispatchOption];
    [self setDispatchEntry: entry
                forKeyPath: keyPath
                  ofObject: object];
}

- (void) removeDispatchActionForKeyPath: (NSString *) keyPath
                               ofObject: (NSObject *) object;
{
    @synchronized (self)
    {
        NSArray * objectWrapper = [NSArray arrayWithObject: object];
        NSMutableDictionary * actionsByKeyPath =
        [_keyPathsByObject objectForKey: objectWrapper];
        
        if ([actionsByKeyPath objectForKey: keyPath] == nil)
            return;
        
        [actionsByKeyPath removeObjectForKey: keyPath];
        [object removeObserver: self forKeyPath: keyPath];
        
        if ([actionsByKeyPath count] == 0)
        {
            [_keyPathsByObject removeObjectForKey: objectWrapper];
        }
    }
}

- (void) removeAllDispatchActions
{
    @synchronized (self)
    {
        NSEnumerator * e = [_keyPathsByObject keyEnumerator];
        NSArray * objectWrapper;
        while (objectWrapper = [e nextObject])
        {
            NSMutableDictionary * keyPaths = [_keyPathsByObject objectForKey: objectWrapper];
            [self removeObserverForAllKeyPaths: keyPaths ofObjectWrapper: objectWrapper];
        }
        [_keyPathsByObject removeAllObjects];
    }
}

- (void) removeAllDispatchActionsOfObject: (NSObject *) object;
{
    @synchronized (self)
    {
        NSArray * objectWrapper = [NSArray arrayWithObject: object];
        NSMutableDictionary * keyPaths = [_keyPathsByObject objectForKey: objectWrapper];
        [self removeObserverForAllKeyPaths: keyPaths ofObjectWrapper: objectWrapper];
        [_keyPathsByObject removeObjectForKey: objectWrapper];
    }
}

-(void) observeValueForKeyPath: (NSString *) keyPath ofObject: (id) object
                        change: (NSDictionary *) change context: (void *) context
{
    NSArray * objectWrapper = [NSArray arrayWithObject: object];
    SEL action;
    DDObserverDispatchOption dispatchOption;
    @synchronized (self)
    {
        NSMutableDictionary * actionsByKeyPath;
        actionsByKeyPath = [_keyPathsByObject objectForKey: objectWrapper];
        if (actionsByKeyPath == nil)
            return;
        
        DDObserverDispatcherEntry * entry = [actionsByKeyPath objectForKey: keyPath];
        if (entry == nil)
            return;
        
        action = [entry action];
        if ([entry hasDispatchOption])
            dispatchOption = [entry dispatchOption];
        else
            dispatchOption = _defaultDispatchOption;
    }
    
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
         keyPath, DDObserverDispatcherKeyPathKey,
         object, DDObserverDispatcherObjectKey,
         change, DDObserverDispatcherChangeKey,
         nil];
    
    if (dispatchOption == DDObserverDispatchOnMainThreadAndWait)
        [_target performSelectorOnMainThread: action withObject: userInfo waitUntilDone: YES];
    else if (dispatchOption == DDObserverDispatchOnMainThread)
        [_target performSelectorOnMainThread: action withObject: userInfo waitUntilDone: NO];
    else // (dispatchOption == DDObserverDispatchOnCallingThread)
        [_target performSelector: action withObject: userInfo];
}

@end

@implementation DDObserverDispatcher (Private)

- (void) removeObserverForAllKeyPaths: (NSMutableDictionary *) keyPaths
                      ofObjectWrapper: (NSArray *) objectWrapper;
{
    NSObject * object = [objectWrapper objectAtIndex: 0];
    NSEnumerator * e = [keyPaths keyEnumerator];
    NSString * keyPath;
    while (keyPath = [e nextObject])
    {
        [object removeObserver: self forKeyPath: keyPath];
    }
}

- (void) setDispatchEntry: (DDObserverDispatcherEntry *) entry
               forKeyPath: (NSString *) keyPath
                 ofObject: (NSObject *) object;
{
    @synchronized (self)
    {
        NSArray * objectWrapper = [NSArray arrayWithObject: object];
        NSMutableDictionary * actionsByKeyPath =
        [_keyPathsByObject objectForKey: objectWrapper];
        
        // Create if it does not yet exist
        if (actionsByKeyPath == nil)
        {
            actionsByKeyPath = [NSMutableDictionary dictionary];
            [_keyPathsByObject setObject: actionsByKeyPath forKey: objectWrapper];
        }
        
        if ([actionsByKeyPath objectForKey: keyPath] == nil)
        {
            [actionsByKeyPath setObject: entry forKey: keyPath];
            [object addObserver: self
                     forKeyPath: keyPath
                        options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                        context: NULL];
        }
        else
            [actionsByKeyPath setObject: entry forKey: keyPath];
    }
}

@end

