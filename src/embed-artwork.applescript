(*
set myTrackData to {{trackId:8996, trackcontainerid:7645}, {trackId:9000, trackcontainerid:7645}, {trackId:9001, trackcontainerid:7645}, {trackId:9002, trackcontainerid:7645}}

embedArtwork(myTrackData, "http://bp3.blogger.com/_NBY6eiHO9Uw/RwUlQAu8i3I/AAAAAAAAA68/SqyO7ShvHBw/s320/Parachutes.jpg")
*)


on embedArtwork(trackData, tempFilePath)
	
	(*
	set tempFilePath to "/tmp/music-artwork.tmp"
	
	tell application "URL Access Scripting"
		download imageUrl to POSIX file tempFilePath
	end tell
*)
	set myData to read POSIX file tempFilePath as data
	
	repeat with trackInfo in trackData
		set trackid to trackid of trackInfo
		set trackContainerId to trackContainerId of trackInfo
		tell application "iTunes"
			set myTrack to track id trackid of playlist id trackContainerId
			tell myTrack
				tell artwork 1
					set data to myData
				end tell
			end tell
		end tell
	end repeat
	
end embedArtwork
