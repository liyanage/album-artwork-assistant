property current_number : 0

on run
	set current_number to current_number + 1
	say "I have counted up to " & current_number & ", next time it will be " & (current_number + 1)
	
	display dialog "This has been directed to Finder with the -setFinderAsDefaultTarget method." buttons {"OK"} default button "OK"
	
	return {a:"These should be returned in a NSDictionary", b:{"Containing", "NSString's", "an", "NSArray", "of", "NSString's"}, C:", an NSArray of NSNumber's, an AppleScript and a procedure call", d:{12, 13.5}, e:ReturnScript, f:displayLabeledArguments as handler}
end run


on open (anItemsList)
	repeat with theItem in anItemsList
		tell application "Finder"
			open theItem
			set theName to name of theItem
		end tell
		say "Opening folder " & theName
	end repeat
end open


on quit
	say "Good bye."
end quit


script ReturnScript
	on run
		say "This is the returned script"
	end run
end script

to displayPositionalArguments(aMessage)
	display dialog aMessage & " displayPositionalArguments" buttons {"OK"} default button "OK"
end displayPositionalArguments

to displayLabeledArguments for aMessage given buttons:aButtonList, default:aButton
	display dialog aMessage & " displayLabeledArguments" buttons aButtonList default button aButton
end displayLabeledArguments