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

#import "DDRunLoopPoker.h"

static const uint32_t kPokeMessage = 100;

@implementation DDRunLoopPoker

+ (id)pokerWithRunLoop:(NSRunLoop *)runLoop;
{
    id o = [[self alloc] initWithRunLoop:runLoop];
    return [o autorelease];
}

- (id)init;
{
    return [self initWithRunLoop:[NSRunLoop currentRunLoop]];
}

- (id)initWithRunLoop:(NSRunLoop *)runLoop;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _runLoop = [runLoop retain];
    _pokerPort = [[NSMachPort port] retain];
    [_runLoop addPort:_pokerPort forMode:NSDefaultRunLoopMode];
    [_runLoop addPort:_pokerPort forMode:NSModalPanelRunLoopMode];
    
    return self;
}

- (void)dealloc
{
    [self dispose];
    
    [super dealloc];
}

- (void)finalize
{
    [self dispose];
    
    [super finalize];
}

- (void)dispose;
{
    if (_pokerPort != nil)
    {
        [_runLoop removePort:_pokerPort forMode:NSModalPanelRunLoopMode];
        [_runLoop removePort:_pokerPort forMode:NSDefaultRunLoopMode];
    }
    [_pokerPort invalidate];
    [_pokerPort release];
    _pokerPort = nil;
    
    [_runLoop release];
    _runLoop = nil;
}

- (void)pokeRunLoop;
{
    NSPortMessage * message = [[NSPortMessage alloc] initWithSendPort:_pokerPort
                                                          receivePort:nil
                                                           components:nil];
    [message autorelease];
    
    [message setMsgid:kPokeMessage];
    [message sendBeforeDate:[NSDate date]];
}

@end
