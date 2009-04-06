//
//  DDRunLoopPokerTest.h
//  DDFoundation
//
//  Created by Dave Dribin on 9/20/08.
//  Copyright 2008 Bit Maki, Inc.. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "DDTestCase.h"

@class DDRunLoopPoker;

@interface DDRunLoopPokerTest : DDTestCase {
    DDRunLoopPoker * _poker;
    BOOL _threadDone;
    NSCondition * _condition;
}

@end
