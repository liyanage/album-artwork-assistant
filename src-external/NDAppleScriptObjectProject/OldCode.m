/*
 *  OldCode.m
 *  NDAppleScriptObjectProject
 *
 *  Created by Nathan Day on Sat Feb 15 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

/*
 * class implementation NDAppleScriptObject (private)
 */
@implementation NDAppleScriptObject (private)

/*
 * + appleScriptObjectWithAEDesc:
 */
+ (id)appleScriptObjectWithAEDesc:(const AEDesc *)aDesc
{
	NSData		* theData;

	theData = [NSData nd_dataWithAEDesc: aDesc];

	return ( theData == nil ) ? nil : [[[self alloc] initWithData:theData] autorelease];
}

/*
 * + objectForAEDesc:
 */
+ (id)objectForAEDesc:(const AEDesc *)aDesc
{
	id			theResult;

#if 0
	char		*theType = (char*)&aDesc->descriptorType;
	NSLog(@"objectForAEDesc: recieved type '%c%c%c%c'\n",theType[0],theType[1],theType[2],theType[3]);
#endif

	switch(aDesc->descriptorType)
	{
		case typeBoolean:						//	1-byte Boolean value
		case typeShortInteger:				//	16-bit integer
									 //		case typeSMInt:							//	16-bit integer
		case typeLongInteger:				//	32-bit integer
									//		case typeInteger:							//	32-bit integer
		case typeShortFloat:					//	SANE single
									//		case typeSMFloat:							//	SANE single
		case typeFloat:						//	SANE double
							  //		case typeLongFloat:						//	SANE double
			//		case typeExtended:						//	SANE extended
	//		case typeComp:							//	SANE comp
		case typeMagnitude:					//	unsigned 32-bit integer
		case typeTrue:							//	TRUE Boolean value
		case typeFalse:						//	FALSE Boolean value
			theResult = [NSNumber nd_numberWithAEDesc:aDesc];
			break;
		case typeChar:							//	unterminated string
			theResult = [NSString nd_stringWithAEDesc:aDesc];
			break;
		case typeAEList:						//	list of descriptor records
			theResult = [NSArray nd_arrayWithAEDesc:aDesc];
			break;
		case typeAERecord:					//	list of keyword-specified
			theResult = [NSDictionary nd_dictionaryWithAEDesc:aDesc];
			break;
		case typeAppleEvent:						//	Apple event record
			theResult = [NSAppleEventDescriptor nd_appleEventDescriptorWithAEDesc:aDesc];
			break;
		case typeAlias:							//	alias record
		case typeFileURL:
			theResult = [NSURL nd_URLWithAEDesc:aDesc];
			break;
			//		case typeEnumerated:					//	enumerated data
	//			break;
		case cScript:							// script data
			theResult = [NDAppleScriptObject appleScriptObjectWithAEDesc:aDesc];
			break;
		case cEventIdentifier:
			theResult = [NSString nd_stringWithAEDesc: aDesc];
			break;
		default:
			theResult = [NSAppleEventDescriptor nd_appleEventDescriptorWithAEDesc:aDesc];
			//			theResult = [NSData nd_dataWithAEDesc: aDesc];
			break;
	}

	return theResult;
}
@end

/*
 * class interface NSString (NDAEDescCreation)
 */
@interface NSString (NDAEDescCreation)
+ (id)nd_stringWithAEDesc:(const AEDesc *)aDesc;
@end

/*
 * class interface NSArray (NDAEDescCreation)
 */
@interface NSArray (NDAEDescCreation)
+ (id)nd_arrayWithAEDesc:(const AEDesc *)aDesc;
@end

/*
 * class interface NSDictionary (NDAEDescCreation)
 */
@interface NSDictionary (NDAEDescCreation)
+ (id)nd_dictionaryWithAEDesc:(const AEDesc *)aDesc;
@end

/*
 * class interface NSData (NDAEDescCreation)
 */
@interface NSData (NDAEDescCreation)
+ (id)nd_dataWithAEDesc:(const AEDesc *)aDesc;
@end

/*
 * class interface NSNumber (NDAEDescCreation)
 */
@interface NSNumber (NDAEDescCreation)
+ (id)nd_numberWithAEDesc:(const AEDesc *)aDesc;
@end

/*
 * class interface NSURL (NDAEDescCreation)
 */
@interface NSURL (NDAEDescCreation)
+ (id)nd_URLWithAEDesc:(const AEDesc *)aDesc;
@end

/*
 * class interface NSAppleEventDescriptor (NDAEDescCreation)
 */
@interface NSAppleEventDescriptor (NDAEDescCreation)
+ (id)nd_appleEventDescriptorWithAEDesc:(const AEDesc *)aDesc;
@end


/*
 * class implementation NSString (NDAEDescCreation)
 */
@implementation NSString (NDAEDescCreation)

/*
 * + nd_stringWithAEDesc:
 */
+ (id)nd_stringWithAEDesc:(const AEDesc *)aDesc
{
	NSData			* theTextData;

	theTextData = [NSData nd_dataWithAEDesc: aDesc];

	return ( theTextData == nil ) ? nil : [[[NSString alloc]initWithData:theTextData encoding:NSMacOSRomanStringEncoding] autorelease];
}

@end

/*
 * class implementation NSArray (NDAEDescCreation)
 */
@implementation NSArray (NDAEDescCreation)

/*
 * + nd_arrayWithAEDesc:
 */
+ (id)nd_arrayWithAEDesc:(const AEDesc *)aDesc
{
	SInt32				theNumOfItems,
	theIndex;
	id						theInstance = nil;

	AECountItems( aDesc, &theNumOfItems );
	theInstance = [NSMutableArray arrayWithCapacity:theNumOfItems];

	for( theIndex = 1; theIndex <= theNumOfItems; theIndex++)
	{
		AEDesc		theDesc = { typeNull, NULL };
		AEKeyword	theAEKeyword;

		if( AEGetNthDesc ( aDesc, theIndex, typeWildCard, &theAEKeyword, &theDesc ) == noErr )
		{
			[theInstance addObject: [NDAppleScriptObject objectForAEDesc: &theDesc]];
			AEDisposeDesc( &theDesc );
		}
	}

	return theInstance;
}

@end

/*
 * class implementation NSDictionary (NDAEDescCreation)
 */
@implementation NSDictionary (NDAEDescCreation)

/*
 * + nd_dictionaryWithAEDesc:
 */
+ (id)nd_dictionaryWithAEDesc:(const AEDesc *)aDesc
{
	id						theInstance = nil;
	AEDesc				theListDesc = { typeNull, NULL };
	AEKeyword			theAEKeyword;

	if( AEGetNthDesc ( aDesc, 1, typeWildCard, &theAEKeyword, &theListDesc ) == noErr )
	{
		SInt32				theNumOfItems,
		theIndex;
		AECountItems( &theListDesc, &theNumOfItems );
		theInstance = [NSMutableDictionary dictionaryWithCapacity:theNumOfItems];

		for( theIndex = 1; theIndex <= theNumOfItems; theIndex += 2)
		{
			AEDesc		theDesc = { typeNull, NULL },
			theKeyDesc = { typeNull, NULL };


			if( ( AEGetNthDesc ( &theListDesc, theIndex + 1, typeWildCard, &theAEKeyword, &theDesc ) == noErr) && ( AEGetNthDesc ( &theListDesc, theIndex, typeWildCard, &theAEKeyword, &theKeyDesc ) == noErr) )
			{
				[theInstance setObject: [NDAppleScriptObject objectForAEDesc: &theDesc] forKey:[NSString nd_stringWithAEDesc: &theKeyDesc]];
				AEDisposeDesc( &theDesc );
				AEDisposeDesc( &theKeyDesc );
			}
			else
			{
				AEDisposeDesc( &theDesc );
				theInstance = nil;
				break;
			}
		}
		AEDisposeDesc( &theListDesc );
	}

	return theInstance;
}

@end

/*
 * class implementation NSData (NDAEDescCreation)
 */
@implementation NSData (NDAEDescCreation)

/*
 * + nd_dataWithAEDesc:
 */
+ (id)nd_dataWithAEDesc:(const AEDesc *)aDesc
{
	NSMutableData *			theInstance;

	theInstance = [NSMutableData dataWithLength: (unsigned int)AEGetDescDataSize(aDesc)];

	if( AEGetDescData(aDesc, [theInstance mutableBytes], [theInstance length]) != noErr )
	{
		theInstance = nil;
	}

	return theInstance;
}

@end

/*
 * class implementation NSNumber (NDAEDescCreation)
 */
@implementation NSNumber (NDAEDescCreation)

/*
 * +nd_numberWithAEDesc:
 */
+ (id)nd_numberWithAEDesc:(const AEDesc *)aDesc
{
	id						theInstance = nil;

	switch(aDesc->descriptorType)
	{
		case typeBoolean:						//	1-byte Boolean value
		{
			BOOL		theBoolean;
			if( AEGetDescData(aDesc, &theBoolean, sizeof(BOOL)) == noErr )
				theInstance = [NSNumber numberWithBool:theBoolean];
			break;
		}
		case typeShortInteger:				//	16-bit integer
									 //		case typeSMInt:							//	16-bit integer
		{
			short int		theInteger;
			if( AEGetDescData(aDesc, &theInteger, sizeof(short int)) == noErr )
				theInstance = [NSNumber numberWithShort: theInteger];
			break;
		}
		case typeLongInteger:				//	32-bit integer
									//		case typeInteger:							//	32-bit integer
		{
			int		theInteger;
			if( AEGetDescData(aDesc, &theInteger, sizeof(int)) == noErr )
				theInstance = [NSNumber numberWithInt: theInteger];
			break;
		}
		case typeShortFloat:					//	SANE single
									//		case typeSMFloat:							//	SANE single
		{
			float		theFloat;
			if( AEGetDescData(aDesc, &theFloat, sizeof(float)) == noErr )
				theInstance = [NSNumber numberWithFloat: theFloat];
			break;
		}
		case typeFloat:						//	SANE double
							  //		case typeLongFloat:						//	SANE double
		{
			double theFloat;
			if( AEGetDescData(aDesc, &theFloat, sizeof(double)) == noErr )
				theInstance = [NSNumber numberWithDouble: theFloat];
			break;
		}
			//		case typeExtended:						//	SANE extended
	//			break;
 //		case typeComp:							//	SANE comp
 //			break;
		case typeMagnitude:					//	unsigned 32-bit integer
		{
			unsigned int		theInteger;
			if( AEGetDescData(aDesc, &theInteger, sizeof(unsigned int)) == noErr )
				theInstance = [NSNumber numberWithUnsignedInt: theInteger];
			break;
		}
		case typeTrue:							//	TRUE Boolean value
			theInstance = [NSNumber numberWithBool:YES];
			break;
		case typeFalse:						//	FALSE Boolean value
			theInstance = [NSNumber numberWithBool:NO];
			break;
		default:
			theInstance = nil;
			break;
	}

	return theInstance;
}

@end

/*
 * class implementation NSURL (NDAEDescCreation)
 */
@implementation NSURL (NDAEDescCreation)

/*
 * + nd_URLWithAEDesc:
 */
+ (id)nd_URLWithAEDesc:(const AEDesc *)aDesc
{
	unsigned int	theSize;
	id					theURL = nil;
	OSAError			theError;

	theSize = (unsigned int)AEGetDescDataSize(aDesc);

	switch(aDesc->descriptorType)
	{
		case typeAlias:							//	alias record
		{
			Handle			theAliasHandle;
			FSRef				theTarget;
			Boolean			theWasChanged;

			theAliasHandle = NewHandle( theSize );
			HLock(theAliasHandle);
			theError = AEGetDescData(aDesc, *theAliasHandle, theSize);
			HUnlock(theAliasHandle);
			if( theError == noErr  && FSResolveAlias( NULL, (AliasHandle)theAliasHandle, &theTarget, &theWasChanged ) == noErr )
			{
				theURL = [NSURL URLWithFSRef:&theTarget];
			}

			DisposeHandle(theAliasHandle);
			break;
		}
		case typeFileURL:					// ???		NOT IMPLEMENTED YET
			NSLog(@"NOT IMPLEMENTED YET: Attempt to create a NSURL from 'typeFileURL' AEDesc" );
			break;
	}

	return theURL;
}

@end

/*
 * class implementation NSAppleEventDescriptor (NDAEDescCreation)
 */
@implementation NSAppleEventDescriptor (NDAEDescCreation)
/*
 * +nd_appleEventDescriptorWithAEDesc:
 */
+ (id)nd_appleEventDescriptorWithAEDesc:(const AEDesc *)aDesc
{
	return [self descriptorWithDescriptorType:aDesc->descriptorType data:[NSData nd_dataWithAEDesc:aDesc]];
}

@end


