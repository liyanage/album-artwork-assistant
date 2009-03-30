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

#import <Cocoa/Cocoa.h>

typedef enum
{
    DDObserverDispatchOnCallingThread,
    DDObserverDispatchOnMainThread,
    DDObserverDispatchOnMainThreadAndWait,
} DDObserverDispatchOption;

@interface DDObserverDispatcher : NSObject
{
    id _target;
    /*
     * This is a two-level dictionary. The first level is key paths, index
     * by object.   The second level is an action indexed by key path.
     * The key of the first index (the object) must also be wrapped in
     * an NSArray, in case it is not copyable.
     */
    NSMutableDictionary * _keyPathsByObject;
    DDObserverDispatchOption _defaultDispatchOption;
}

- (id) initWithTarget: (id) target
defaultDispatchOption: (DDObserverDispatchOption) dispatchOption;

- (id) initWithTarget: (id) target;

- (void) setDispatchAction: (SEL) action
                forKeyPath: (NSString *) keyPath
                  ofObject: (NSObject *) object;

- (void) setDispatchAction: (SEL) action
                forKeyPath: (NSString *) keyPath
                  ofObject: (NSObject *) object
            dispatchOption: (DDObserverDispatchOption) dispatchOption;

- (void) removeDispatchActionForKeyPath: (NSString *) keyPath
                               ofObject: (NSObject *) object;

- (void) removeAllDispatchActions;

- (void) removeAllDispatchActionsOfObject: (NSObject *) object;

@end

extern NSString * DDObserverDispatcherKeyPathKey;
extern NSString * DDObserverDispatcherObjectKey;
extern NSString * DDObserverDispatcherChangeKey;
