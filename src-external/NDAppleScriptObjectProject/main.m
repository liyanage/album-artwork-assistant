#import <Foundation/Foundation.h>
#import "NDAppleScriptObject.h"
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"
#import "NDComponentInstance.h"

const BOOL		kUseCompiledAppleScriptFile = YES;

void createAndExecuteScriptObject( NSString * aPath );

const OSType	kProjectBuilderCreatorCode = 'pbxa';

/*
 * class interface SendTarget : NSObject <NDAppleScriptObjectSendEvent, NDAppleScriptObjectActive>
 */
@interface SendTarget : NSObject <NDAppleScriptObjectSendEvent, NDAppleScriptObjectActive>
{
	NDAppleScriptObject		* appleScriptObject;
	unsigned int				OK_Enough;
}
+ (id)sendTargetWithAppleScriptObject:(NDAppleScriptObject *)anObject;
@end

/*
 * main
 */
int main (int argc, const char * argv[])
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString		* thePath;

	if( kUseCompiledAppleScriptFile )
		thePath = @"../Test Script.scpt";
	else
		thePath = @"../Test Script.applescript";

	createAndExecuteScriptObject( thePath );

	[pool release];
	return 0;
}

/*
 * createAndExecuteScriptObject()
 */
void createAndExecuteScriptObject( NSString * aPath )
{
	NSString					* theScriptText;
	NDAppleScriptObject		* theScriptObject;

	/*
	 * compiling and executing a script within a string
	 */
	[NDAppleScriptObject compileExecuteString:@"say \"This is a compiled and executed string\"\n"];

	if( [[aPath pathExtension] isEqualToString:@"applescript"] )
	{
		/*
		 * This shows creating a script object from a string
		 */		
		theScriptText = [NSString stringWithContentsOfFile:aPath];
		theScriptObject = [NDAppleScriptObject appleScriptObjectWithString:theScriptText];
	}
	else
	{
//		NDComponentInstance		* theComp;
		/*
		 * This shows creating a script object from a compiled apple script file.
		 */
		theScriptObject = [NDAppleScriptObject appleScriptObjectWithContentsOfFile:aPath];
//		theComp = [NDComponentInstance sharedComponentInstance];
//		theComp = [NDComponentInstance componentInstance];
//		theComp = [NDComponentInstance componentInstanceWithComponent:[NDComponentInstance findNextComponent]];
//		theScriptObject = [NDAppleScriptObject appleScriptObjectWithContentsOfFile:aPath componentInstance:theComp];
	}
	
	if( theScriptObject )
	{
		id					theResult;
		NSArray			* theEventIdentifierList;
		SendTarget		* theSendTarget;

		/*
			set target object which implements the NDAppleScriptObjectSendEvent protocol, it simple prints a message and then passes all of the paramter back to NDAppleScriptObject which also implements the NDAppleScriptObjectSendEvent protocol.
		 */
		theSendTarget = [SendTarget sendTargetWithAppleScriptObject:theScriptObject];
		[[theScriptObject componentInstance] setAppleEventSendTarget:theSendTarget];

		/*
			set target object which implements the NDAppleScriptObjectActive protocol, it simple prints a message and then calls NDAppleScriptObject which also implements the NDAppleScriptObjectActive protocol.
		 */
		[[theScriptObject componentInstance] setActiveTarget:theSendTarget];

		/*
			display the events the script object responded
		 */
		theEventIdentifierList = [theScriptObject arrayOfEventIdentifier];
		printf("This script responds to the events %s\n", [[theEventIdentifierList description] lossyCString]);

		/*
			display the propertys the script object contains
		 */
		printf("This script has the following properties %s\n", [[[theScriptObject arrayOfPropertyNames] description] lossyCString]);
		printf("The value of current_number is %s\n", [[[theScriptObject valueForPropertyNamed:@"current_number"] description] lossyCString]);
		[theScriptObject setPropertyNamed:@"current_number" toValue:[NSNumber numberWithUnsignedInt:100] define:NO];
		printf("Now the value of current_number is %s\n", [[[theScriptObject valueForPropertyNamed:@"current_number"] description] lossyCString]);

		/*
			set Finder as the default target, for display dialog etc.
		 */
//		[[theScriptObject componentInstance] setDefaultTargetAsCreator:kProjectBuilderCreatorCode];
		[[theScriptObject componentInstance] setFinderAsDefaultTarget];

		/*
		 * display the scripts source
		 */
		printf("The script\n\n%s\n\ngives us\n\n", [[theScriptObject description] lossyCString]);

		/*
		 * set execution mode flags
		 */
		[theScriptObject setExecutionModeFlags:kOSAModeCanInteract];

		
		/*
		 * exectue and get result
		 */
		[theScriptObject execute];
		theResult = [theScriptObject resultObject];

		/*
			the result can be returned as a object, NSArray, NSDictionary, NSNumber, NSString, NSURL, NSAppleEventDescriptor even an NDAppleScriptObject which can then be executed
		 */
		if( [theResult isKindOfClass:[NDAppleScriptObject class]] )
		{
			[theResult execute];
		}
		else
		{
			printf("Resulting objects\n%s\n\n",[[theResult description] lossyCString]);
		}

		/*
		 * lets display the result as a descriptor
		 */
		printf("Result as a descriptor description\n%s\n\n", [[[theScriptObject resultAppleEventDescriptor] description] lossyCString]);

		/*
		 * lets display the result as a string
		 */
		printf("Result as a string\n%s\n\n", [[theScriptObject resultAsString]  lossyCString]);

		/*
		 call the subroutine with a string
		 */
		if( [theScriptObject respondsToSubroutine:@"displayPositionalArguments"] )
		{
			printf( "The script does respond to the subroutine named 'displayPositionalArguments'\n" );
			[theScriptObject executeSubroutineNamed:@"displayPositionalArguments" arguments:@"This dialog is being displayed by the routine", nil];
		}
		else
			printf( "The script does NOT respond to the subroutine named 'displayPositionalArguments'\n" );

		/*
		 call the subroutine with a string
		 */
		if( [theScriptObject respondsToSubroutine:@"displayLabeledArguments"] )
		{
			printf( "The script does respond to the subroutine named 'displayLabeledArguments'\n" );
//			id			theGivenParam = [NSAppleEventDescriptor userRecordDescriptorWithObjectAndKeys:[NSArray arrayWithObjects:@"Two", @"One", nil], @"buttons", @"One", @"default", nil];
			[theScriptObject executeSubroutineNamed:@"displayLabeledArguments" labelsAndArguments: keyASPrepositionFor, @"This dialog is being displayed by the routine", keyASPrepositionGiven, [NSArray arrayWithObjects:@"Two", @"One", nil], @"buttons", @"One", @"default", nil];
		}
		else
			printf( "The script does NOT respond to the subroutine named 'displayLabeledArguments'\n" );
		
		/*
			executeOpen takes an array of paths or urls and passes them to the script through the open event as a list of aliases
		 */
		printf("Attempt to open '../Source' '../build'\n");
		[theScriptObject executeOpen:[NSArray arrayWithObjects:@"../Classes", @"../build", nil]];

		/*
			test if the script executes the apple event 'quit' and if so execute it
		 */
		if( [theScriptObject respondsToEventClass:kCoreEventClass eventID:kAEQuitApplication] )
		{
			[theScriptObject executeEvent:[NSAppleEventDescriptor quitEventDescriptorWithTargetDescriptor:[theScriptObject appleEventTarget]]];
		}
		else
		{
			printf("Script does not respond to kCoreEventClass:kAEQuitApplication\n");
		}
		/*
		 * write the compiled script back out to the file so that any varible bindings are updated
		 */
		if( [[aPath pathExtension] isEqualToString:@"scpt"] )
		{
			[theScriptObject writeToFile:aPath];
		}
	}
	else
	{
		printf("Could not create the AppleScript object\n");
	}
}

/*
 * class implementation SendTarget
 */
@implementation SendTarget

/*
 * +sendTargetWithAppleScriptObject:
 */
+ (id)sendTargetWithAppleScriptObject:(NDAppleScriptObject *)anObject
{
	SendTarget		* theInstance;

	if( theInstance = [[[self alloc] init] autorelease] )
	{
		theInstance->appleScriptObject = [anObject retain];
		theInstance->OK_Enough = 0;
	}
	return theInstance;
}

/*
 * -dealloc
 */
-(void)dealloc
{
	[appleScriptObject release];
}

/*
 * sendAppleEvent:sendMode:sendPriority:timeOutInTicks:idleProc:filterProc:
 */
- (NSAppleEventDescriptor *)sendAppleEvent:(NSAppleEventDescriptor *)theAppleEventDescriptor sendMode:(AESendMode)aSendMode sendPriority:(AESendPriority)aSendPriority timeOutInTicks:(long)aTimeOutInTicks idleProc:(AEIdleUPP)anIdleProc filterProc:(AEFilterUPP)aFilterProc
{	
	OK_Enough++;
	if( OK_Enough < 2 )
		printf("sending say event to %s...\n\n", [theAppleEventDescriptor isTargetCurrentProcess] ? "self" : "Finder" );
	else if( OK_Enough == 2 )
		printf("sending open event to %s...\t\tyou get the idea.\n\n", [theAppleEventDescriptor isTargetCurrentProcess] ? "self" : "Finder" );

	printf( "\n%s\n", [[theAppleEventDescriptor description] lossyCString] );
	
	return [[appleScriptObject componentInstance] sendAppleEvent:theAppleEventDescriptor sendMode:aSendMode sendPriority:aSendPriority timeOutInTicks:aTimeOutInTicks idleProc:anIdleProc filterProc:aFilterProc];
}

/*
 * -appleScriptActive
 */
- (BOOL)appleScriptActive
{
	printf("* active\n");
	return [[appleScriptObject componentInstance] appleScriptActive];
}

@end

#if 1

#define STRINGFORFOURCHARCODE( XXXX ) case XXXX: return [NSString stringWithCString: #XXXX]
//#define STRINGFORFOURCHARCODE( XXXX ) case XXXX: return @ ## #XXXX
#define DUALSTRINGFORFOURCHARCODE( XXXX, YYYY ) case XXXX: return [NSString stringWithFormat:@"%s/%s", #XXXX, #YYYY ]

@implementation NSAppleEventDescriptor (DEBUGGING)

NSString * displayStringForType( OSType aType );
NSString * displayStringForASKeyWord( AEKeyword aType );
NSString * displayStringForAEKeyWord( AEKeyword aType );

- (NSString *)description
{
	OSType		theType = [self descriptorType];
	NSString		* theDescription = nil;
	switch(theType)
	{
		case typeBoolean:						//	1-byte Boolean value
		case typeShortInteger:				//	16-bit integer
		case typeLongInteger:				//	32-bit integer
		case typeShortFloat:					//	SANE single
		case typeFloat:						//	SANE double
		case typeMagnitude:					//	unsigned 32-bit integer
		case typeTrue:							//	TRUE Boolean value
		case typeFalse:						//	FALSE Boolean value
//		case typeChar:							//	unterminated string
		case typeAlias:						//	alias record
		case typeFileURL:
		case cScript:							// script data
		case cEventIdentifier:
			theDescription = [NSString stringWithFormat:@"<%@>%@", displayStringForType(theType), [self objectValue]];
			break;
		case typeText:							//	unterminated string
		case kTXNUnicodeTextData:			//	unicode string
			theDescription = [NSString stringWithFormat:@"<%@>\"%@\"", displayStringForType(theType), [self objectValue]];
			break;
		case cType:
			theDescription = [NSString stringWithFormat:@"<cType>%@", NSFileTypeForHFSTypeCode( *(OSType*)[[self data] bytes])];
			break;
		case typeAEList:						//	list of descriptor records
		{
			SInt32						theNumOfItems,
											theIndex;
			NSMutableString			* theString;

			theNumOfItems = [self numberOfItems];
			theString = [NSMutableString stringWithString:@"<typeAEList>( "];

			for( theIndex = 1; theIndex < theNumOfItems; theIndex++)
			{
				[theString appendFormat:@"%@, ", [self descriptorAtIndex:theIndex]];
			}
			[theString appendFormat:@"%@ )", [self descriptorAtIndex:theNumOfItems]];
			theDescription = theString;
			break;
		}
		case typeAERecord:					//	list of keyword-specified
		{
			unsigned int		theIndex,
									theNumOfItems = [self numberOfItems];
			NSMutableString	* theString = [NSMutableString stringWithString:@"<typeAERecord>{\n"];

			for( theIndex = 1; theIndex <= theNumOfItems; theIndex++)
			{
				AEKeyword		theKeyWord = [self keywordForDescriptorAtIndex:theIndex];
				[theString appendFormat:@"\t%@ = %@;\n", displayStringForAEKeyWord( theKeyWord ), [self descriptorForKeyword:theKeyWord]];
			}
			[theString appendString:@"}\n" ];
			theDescription = theString;
			break;
		}
		case typeNull:
			theDescription = @"<typeNull>null";
			break;
		case keyProcessSerialNumber:
		{
			ProcessSerialNumber		* theProcessSN = (ProcessSerialNumber*)[self data];
			theDescription = [NSString stringWithFormat:@"<keyProcessSerialNumber>0x%x %x", theProcessSN->highLongOfPSN, theProcessSN->lowLongOfPSN ];
			break;
		}
		case cObjectSpecifier:
		{
			NSMutableString		* theString;
			unsigned int			theIndex;
			AEKeyword			theDescKeys[] = { keyAEDesiredClass, keyAEContainer, keyAEKeyForm, keyAEKeyData, 0 };
			theString = [NSMutableString stringWithFormat:@"<cObjectSpecifier>\n{"];
			for( theIndex = 0; theDescKeys[theIndex] != 0; theIndex++ )
			{
				NSAppleEventDescriptor		* theDesc = [self descriptorForKeyword:theDescKeys[theIndex]];
				[theString appendFormat:@"\t%@ = %@;\n", displayStringForASKeyWord(theDescKeys[theIndex]), theDesc];
			}
			[theString appendString:@"\n};\n"];
			break;
		}
		case typeAppleEvent:
		{
			int	theIndex,
			theNumberOfItems = [self numberOfItems];
			NSMutableString		* theString;
			AEKeyword			theAttKeys[] = { keyEventClassAttr, keyEventIDAttr, keyTransactionIDAttr, keyReturnIDAttr, keyAddressAttr, keyOptionalKeywordAttr, keyTimeoutAttr, keyInteractLevelAttr, keyEventSourceAttr, keyMissedKeywordAttr, keyOriginalAddressAttr, keyAcceptTimeoutAttr, 0 };
			theString = [NSMutableString stringWithString:@"<typeAppleEvent>{\nattributes\n"];
			
			for( theIndex = 0; theAttKeys[theIndex] != 0; theIndex++ )
			{
				NSAppleEventDescriptor		* theAtt = [self attributeDescriptorForKeyword:theAttKeys[theIndex]];
				if( theAtt )
					[theString appendFormat:@"\t%@ = %@;\n", displayStringForAEKeyWord(theAttKeys[theIndex]), theAtt];
			}

			[theString appendString:@"\nparameters\n" ];
			for( theIndex = 1; theIndex <= theNumberOfItems; theIndex++ )
			{
				AEKeyword		theKeyWord = [self keywordForDescriptorAtIndex:theIndex];
				[theString appendFormat:@"\t%@ = %@;\n", displayStringForAEKeyWord( theKeyWord ), [self descriptorForKeyword:theKeyWord]];
			}
			[theString appendString:@"}\n"];
			theDescription = theString;
		}
			break;
		default:
			theDescription = [NSString stringWithFormat:@"<%@>[%@]", NSFileTypeForHFSTypeCode(theType), [self data]];
			break;
	}
	return theDescription;
}

NSString * displayStringForType( OSType aType )
{
	switch( aType )
	{
		STRINGFORFOURCHARCODE( typeBoolean );
		STRINGFORFOURCHARCODE( typeShortInteger );
		STRINGFORFOURCHARCODE( typeLongInteger );
		STRINGFORFOURCHARCODE( typeShortFloat );
		STRINGFORFOURCHARCODE( typeFloat );
		STRINGFORFOURCHARCODE( typeMagnitude );
		STRINGFORFOURCHARCODE( typeTrue );
		STRINGFORFOURCHARCODE( typeFalse );
//		STRINGFORFOURCHARCODE( cType );
		STRINGFORFOURCHARCODE( typeText );
		STRINGFORFOURCHARCODE( kTXNUnicodeTextData );
		STRINGFORFOURCHARCODE( typeAEList );
		STRINGFORFOURCHARCODE( typeAERecord );
		STRINGFORFOURCHARCODE( typeAlias );
		STRINGFORFOURCHARCODE( typeFileURL );
		STRINGFORFOURCHARCODE( cScript );
		STRINGFORFOURCHARCODE( cEventIdentifier );
		STRINGFORFOURCHARCODE( typeNull );
		STRINGFORFOURCHARCODE( keyProcessSerialNumber );
		STRINGFORFOURCHARCODE( cObjectSpecifier );
		STRINGFORFOURCHARCODE( typeAppleEvent );
		STRINGFORFOURCHARCODE( typeType );
		default: return NSFileTypeForHFSTypeCode(aType);
	}
}

NSString * displayStringForASKeyWord( AEKeyword aType )
{
	switch( aType )
	{
		STRINGFORFOURCHARCODE( keyASReturning );
		STRINGFORFOURCHARCODE( keyASSubroutineName );
		STRINGFORFOURCHARCODE( keyASPositionalArgs );
		STRINGFORFOURCHARCODE( keyASArg );
		STRINGFORFOURCHARCODE( keyASUserRecordFields );
		STRINGFORFOURCHARCODE( keyASPrepositionAt );
		STRINGFORFOURCHARCODE( keyASPrepositionIn );
		STRINGFORFOURCHARCODE( keyASPrepositionFrom );
		STRINGFORFOURCHARCODE( keyASPrepositionFor );
		STRINGFORFOURCHARCODE( keyASPrepositionTo );
		STRINGFORFOURCHARCODE( keyASPrepositionThru );
		STRINGFORFOURCHARCODE( keyASPrepositionThrough );
		STRINGFORFOURCHARCODE( keyASPrepositionBy );
		STRINGFORFOURCHARCODE( keyASPrepositionOn );
		STRINGFORFOURCHARCODE( keyASPrepositionInto );
		STRINGFORFOURCHARCODE( keyASPrepositionOnto );
		STRINGFORFOURCHARCODE( keyASPrepositionBetween );
		STRINGFORFOURCHARCODE( keyASPrepositionAgainst );
		STRINGFORFOURCHARCODE( keyASPrepositionOutOf );
		STRINGFORFOURCHARCODE( keyASPrepositionInsteadOf );
		STRINGFORFOURCHARCODE( keyASPrepositionAsideFrom );
		STRINGFORFOURCHARCODE( keyASPrepositionAround );
		STRINGFORFOURCHARCODE( keyASPrepositionBeside );
		STRINGFORFOURCHARCODE( keyASPrepositionBeneath );
		STRINGFORFOURCHARCODE( keyASPrepositionUnder );
		STRINGFORFOURCHARCODE( keyASPrepositionOver );
		STRINGFORFOURCHARCODE( keyASPrepositionAbove );
		STRINGFORFOURCHARCODE( keyASPrepositionBelow );
		STRINGFORFOURCHARCODE( keyASPrepositionApartFrom );
		STRINGFORFOURCHARCODE( keyASPrepositionGiven );
		STRINGFORFOURCHARCODE( keyASPrepositionWith );
		STRINGFORFOURCHARCODE( keyASPrepositionWithout );
		STRINGFORFOURCHARCODE( keyASPrepositionAbout );
		STRINGFORFOURCHARCODE( keyASPrepositionSince );
		STRINGFORFOURCHARCODE( keyASPrepositionUntil );

		default: return NSFileTypeForHFSTypeCode(aType);
	}
}

NSString * displayStringForAEKeyWord( AEKeyword aType )
{
	switch( aType )
	{
		DUALSTRINGFORFOURCHARCODE( keyDirectObject, keyAEResult );
		STRINGFORFOURCHARCODE( keyErrorNumber );
		STRINGFORFOURCHARCODE( keyErrorString );
		STRINGFORFOURCHARCODE( keyProcessSerialNumber );
		STRINGFORFOURCHARCODE( keyPreDispatch );
		STRINGFORFOURCHARCODE( keySelectProc );
		STRINGFORFOURCHARCODE( keyAERecorderCount );
		STRINGFORFOURCHARCODE( keyAEVersion );

		STRINGFORFOURCHARCODE( keyAEAngle );
		STRINGFORFOURCHARCODE( keyAEArcAngle );
		STRINGFORFOURCHARCODE( keyAEBaseAddr );
		STRINGFORFOURCHARCODE( keyAEBestType );
		STRINGFORFOURCHARCODE( keyAEBgndColor );
		STRINGFORFOURCHARCODE( keyAEBgndPattern );
		STRINGFORFOURCHARCODE( keyAEBounds );
		STRINGFORFOURCHARCODE( keyAECellList );
		STRINGFORFOURCHARCODE( keyAEClassID );
		STRINGFORFOURCHARCODE( keyAEColor );
		STRINGFORFOURCHARCODE( keyAEColorTable );
		STRINGFORFOURCHARCODE( keyAECurveHeight );
		STRINGFORFOURCHARCODE( keyAECurveWidth );
		STRINGFORFOURCHARCODE( keyAEDashStyle );
		STRINGFORFOURCHARCODE( keyAEData );
		STRINGFORFOURCHARCODE( keyAEDefaultType );
		STRINGFORFOURCHARCODE( keyAEDefinitionRect );
		STRINGFORFOURCHARCODE( keyAEDescType );
		STRINGFORFOURCHARCODE( keyAEDestination );
		STRINGFORFOURCHARCODE( keyAEDoAntiAlias );
		STRINGFORFOURCHARCODE( keyAEDoDithered );
		STRINGFORFOURCHARCODE( keyAEDoRotate );
		STRINGFORFOURCHARCODE( keyAEDoScale );
		STRINGFORFOURCHARCODE( keyAEDoTranslate );
		STRINGFORFOURCHARCODE( keyAEEditionFileLoc );
		STRINGFORFOURCHARCODE( keyAEElements );
		STRINGFORFOURCHARCODE( keyAEEndPoint );
		DUALSTRINGFORFOURCHARCODE( keyAEEventClass, keyEventClassAttr );
		STRINGFORFOURCHARCODE( keyAEEventID );
		STRINGFORFOURCHARCODE( keyAEFile );
		STRINGFORFOURCHARCODE( keyAEFileType );
		STRINGFORFOURCHARCODE( keyAEFillColor );
		STRINGFORFOURCHARCODE( keyAEFillPattern );
		STRINGFORFOURCHARCODE( keyAEFlipHorizontal );
		STRINGFORFOURCHARCODE( keyAEFlipVertical );
		STRINGFORFOURCHARCODE( keyAEFont );
		STRINGFORFOURCHARCODE( keyAEFormula );
		STRINGFORFOURCHARCODE( keyAEGraphicObjects );
		STRINGFORFOURCHARCODE( keyAEID );
		STRINGFORFOURCHARCODE( keyAEImageQuality );
		STRINGFORFOURCHARCODE( keyAEInsertHere );
		STRINGFORFOURCHARCODE( keyAEKeyForms );
		STRINGFORFOURCHARCODE( keyAEKeyword );
		STRINGFORFOURCHARCODE( keyAELevel );
		STRINGFORFOURCHARCODE( keyAELineArrow );
		STRINGFORFOURCHARCODE( keyAEName );
		STRINGFORFOURCHARCODE( keyAENewElementLoc );
		STRINGFORFOURCHARCODE( keyAEObject );
		STRINGFORFOURCHARCODE( keyAEObjectClass );
//		STRINGFORFOURCHARCODE( keyAEOffStyles, keyAEOffset );
		STRINGFORFOURCHARCODE( keyAEOnStyles );
		STRINGFORFOURCHARCODE( keyAEParameters );
		STRINGFORFOURCHARCODE( keyAEParamFlags );
		STRINGFORFOURCHARCODE( keyAEPenColor );
		STRINGFORFOURCHARCODE( keyAEPenPattern );
		STRINGFORFOURCHARCODE( keyAEPenWidth );
		STRINGFORFOURCHARCODE( keyAEPixelDepth );
		STRINGFORFOURCHARCODE( keyAEPixMapMinus );
		STRINGFORFOURCHARCODE( keyAEPMTable );
		STRINGFORFOURCHARCODE( keyAEPointList );
		STRINGFORFOURCHARCODE( keyAEPointSize );
		STRINGFORFOURCHARCODE( keyAEPosition );
		STRINGFORFOURCHARCODE( keyAEPropData );
		STRINGFORFOURCHARCODE( keyAEProperties );
		STRINGFORFOURCHARCODE( keyAEProperty );
		STRINGFORFOURCHARCODE( keyAEPropFlags );
		STRINGFORFOURCHARCODE( keyAEPropID );
		STRINGFORFOURCHARCODE( keyAEProtection );
		STRINGFORFOURCHARCODE( keyAERenderAs );
		STRINGFORFOURCHARCODE( keyAERequestedType );
//		STRINGFORFOURCHARCODE( keyAEResult );
		STRINGFORFOURCHARCODE( keyAEResultInfo );
		STRINGFORFOURCHARCODE( keyAERotation );
		STRINGFORFOURCHARCODE( keyAERotPoint );
		STRINGFORFOURCHARCODE( keyAERowList );
		STRINGFORFOURCHARCODE( keyAESaveOptions );
		STRINGFORFOURCHARCODE( keyAEScale );
		STRINGFORFOURCHARCODE( keyAEScriptTag );
		STRINGFORFOURCHARCODE( keyAEShowWhere );
		STRINGFORFOURCHARCODE( keyAEStartAngle );
		STRINGFORFOURCHARCODE( keyAEStartPoint );
		STRINGFORFOURCHARCODE( keyAEStyles );
		STRINGFORFOURCHARCODE( keyAESuiteID );
		STRINGFORFOURCHARCODE( keyAEText );
		STRINGFORFOURCHARCODE( keyAETextColor );
		STRINGFORFOURCHARCODE( keyAETextFont );
		STRINGFORFOURCHARCODE( keyAETextPointSize );
		STRINGFORFOURCHARCODE( keyAETextStyles );
		STRINGFORFOURCHARCODE( keyAETextLineHeight );
		STRINGFORFOURCHARCODE( keyAETextLineAscent );
		STRINGFORFOURCHARCODE( keyAETheText );
		STRINGFORFOURCHARCODE( keyAETransferMode );
		STRINGFORFOURCHARCODE( keyAETranslation );
		STRINGFORFOURCHARCODE( keyAETryAsStructGraf );
		STRINGFORFOURCHARCODE( keyAEUniformStyles );
		STRINGFORFOURCHARCODE( keyAEUpdateOn );
		STRINGFORFOURCHARCODE( keyAEUserTerm );
		STRINGFORFOURCHARCODE( keyAEWindow );
		STRINGFORFOURCHARCODE( keyAEWritingCode );
		STRINGFORFOURCHARCODE( keyAETSMDocumentRefcon );
		STRINGFORFOURCHARCODE( keyAEServerInstance );
		STRINGFORFOURCHARCODE( keyAETheData );
		STRINGFORFOURCHARCODE( keyAEFixLength );
		STRINGFORFOURCHARCODE( keyAEUpdateRange );
		STRINGFORFOURCHARCODE( keyAECurrentPoint );
		STRINGFORFOURCHARCODE( keyAEBufferSize );
		STRINGFORFOURCHARCODE( keyAEMoveView );
		STRINGFORFOURCHARCODE( keyAENextBody );
		STRINGFORFOURCHARCODE( keyAETSMScriptTag );
		STRINGFORFOURCHARCODE( keyAETSMTextFont );
		STRINGFORFOURCHARCODE( keyAETSMTextFMFont );
		STRINGFORFOURCHARCODE( keyAETSMTextPointSize );
		STRINGFORFOURCHARCODE( keyAETSMEventRecord );
		STRINGFORFOURCHARCODE( keyAETSMEventRef );
		STRINGFORFOURCHARCODE( keyAETextServiceEncoding );
		STRINGFORFOURCHARCODE( keyAETextServiceMacEncoding );
		STRINGFORFOURCHARCODE( keyAETSMGlyphInfoArray );
		STRINGFORFOURCHARCODE( keyAEHiliteRange );
		STRINGFORFOURCHARCODE( keyAEPinRange );
		STRINGFORFOURCHARCODE( keyAEClauseOffsets );
//		STRINGFORFOURCHARCODE( keyAEOffset );
		STRINGFORFOURCHARCODE( keyAEPoint );
		STRINGFORFOURCHARCODE( keyAELeftSide );
		STRINGFORFOURCHARCODE( keyAERegionClass );
		STRINGFORFOURCHARCODE( keyAEDragging );

		STRINGFORFOURCHARCODE( keyAECompOperator );
		STRINGFORFOURCHARCODE( keyAELogicalTerms );
		STRINGFORFOURCHARCODE( keyAELogicalOperator );
		STRINGFORFOURCHARCODE( keyAEObject1 );
		STRINGFORFOURCHARCODE( keyAEObject2 );
		STRINGFORFOURCHARCODE( keyAEDesiredClass );
		DUALSTRINGFORFOURCHARCODE( keyAEContainer, keyOriginalAddressAttr );
		STRINGFORFOURCHARCODE( keyAEKeyForm );
		STRINGFORFOURCHARCODE( keyAEKeyData );
		STRINGFORFOURCHARCODE( keyAERangeStart );
		STRINGFORFOURCHARCODE( keyAERangeStop );
		STRINGFORFOURCHARCODE( keyAECompareProc );
		STRINGFORFOURCHARCODE( keyAECountProc );
		STRINGFORFOURCHARCODE( keyAEMarkTokenProc );
		STRINGFORFOURCHARCODE( keyAEMarkProc );
		STRINGFORFOURCHARCODE( keyAEAdjustMarksProc );
		STRINGFORFOURCHARCODE( keyAEGetErrDescProc );

		STRINGFORFOURCHARCODE( keyAEWhoseRangeStart );
		STRINGFORFOURCHARCODE( keyAEWhoseRangeStop );
		STRINGFORFOURCHARCODE( keyAEIndex );
		STRINGFORFOURCHARCODE( keyAETest );
		STRINGFORFOURCHARCODE( typeKeyword );
		STRINGFORFOURCHARCODE( keyTransactionIDAttr );
		STRINGFORFOURCHARCODE( keyReturnIDAttr );
//		STRINGFORFOURCHARCODE( keyEventClassAttr );
		STRINGFORFOURCHARCODE( keyEventIDAttr );
		STRINGFORFOURCHARCODE( keyAddressAttr );
		STRINGFORFOURCHARCODE( keyOptionalKeywordAttr );
		STRINGFORFOURCHARCODE( keyTimeoutAttr );
		STRINGFORFOURCHARCODE( keyInteractLevelAttr );
		STRINGFORFOURCHARCODE( keyEventSourceAttr );
		STRINGFORFOURCHARCODE( keyMissedKeywordAttr );
//		STRINGFORFOURCHARCODE( keyOriginalAddressAttr );
		STRINGFORFOURCHARCODE( keyAcceptTimeoutAttr );

		STRINGFORFOURCHARCODE( keyUserNameAttr );
		STRINGFORFOURCHARCODE( keyUserPasswordAttr );
		STRINGFORFOURCHARCODE( keyDisableAuthenticationAttr );
		STRINGFORFOURCHARCODE( keyXMLDebuggingAttr );
		STRINGFORFOURCHARCODE( keyRPCMethodName );
		STRINGFORFOURCHARCODE( keyRPCMethodParam );
		STRINGFORFOURCHARCODE( keyRPCMethodParamOrder );

		STRINGFORFOURCHARCODE( keyAEPOSTHeaderData );
		STRINGFORFOURCHARCODE( keyAEReplyHeaderData );
		STRINGFORFOURCHARCODE( keyAEXMLRequestData );
		STRINGFORFOURCHARCODE( keyAEXMLReplyData );
		STRINGFORFOURCHARCODE( keyAdditionalHTTPHeaders );
		STRINGFORFOURCHARCODE( keySOAPAction );
		STRINGFORFOURCHARCODE( keySOAPMethodNameSpace );
		STRINGFORFOURCHARCODE( keySOAPMethodNameSpaceURI );
		STRINGFORFOURCHARCODE( keySOAPSchemaVersion );
		STRINGFORFOURCHARCODE( keySOAPStructureMetaData );
		STRINGFORFOURCHARCODE( keySOAPSMDNamespace );
		STRINGFORFOURCHARCODE( keySOAPSMDNamespaceURI );
		STRINGFORFOURCHARCODE( keySOAPSMDType );
		default: return displayStringForASKeyWord( aType );
	}
}

@end

#endif

