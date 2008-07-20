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

#import <Foundation/Foundation.h>


/**
 * Implements the "Find-or-Create Efficiently" as described in the
 * "Efficiently Importing Legacy Data" chapter of the "Core Data Programming
 * Guide".  It is more flexible in that you can delete or update effeciently
 * as well.  As such, you can mirror a Core Data collection with an external
 * data set.
 *
 * http://developer.apple.com/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 */
@interface DDSequenceComparator : NSEnumerator
{
    NSEnumerator * _sourceSequence;
    NSString * _sourceKey;
    NSEnumerator * _finalSequence;
    NSString * _finalKey;

    id _currentSourceObject;
    id _currentFinalObject;
    BOOL _advanceSource;
    BOOL _advanceFinal;
}

+ (id) comparatorWithSourceEnumerator: (NSEnumerator *) sourceEnumerator
                            sourceKey: (NSString *) sourceKey
                      finalEnumerator: (NSEnumerator *) finalEnumerator
                             finalKey: (NSString *) finalKey;

+ (id) comparatorWithSourceArray: (NSArray *) sourceArray
                       sourceKey: (NSString *) sourceKey
                      finalArray: (NSArray *) finalArray
                        finalKey: (NSString *) finalKey;

- (id) initWithSourceEnumerator: (NSEnumerator *) sourceEnumerator
                      sourceKey: (NSString *) sourceKey
                finalEnumerator: (NSEnumerator *) finalEnumerator
                       finalKey: (NSString *) finalKey;

- (id) nextObject;

- (id) currentSourceObject;

- (id) currentFinalObject;

@end

#define DDSequenceComparatorDelete NSOrderedAscending
#define DDSequenceComparatorUpdate NSOrderedSame
#define DDSequenceComparatorAdd NSOrderedDescending
