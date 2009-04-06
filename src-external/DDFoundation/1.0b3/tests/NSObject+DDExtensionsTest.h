//
//  NSObject+DDExtensionsTest.h
//  DDFoundation
//
//  Created by Dave Dribin on 5/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface NSObject_DDExtensionsTest : SenTestCase
{
    int _count;
    BOOL _done;
    BOOL _invoked;
    int _result;
}

@property BOOL done;
@property BOOL invoked;

@end
