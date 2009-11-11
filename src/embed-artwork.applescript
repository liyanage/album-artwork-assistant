
on embedArtwork(trackData, tempFilePath)
	
	set myData to read POSIX file tempFilePath as data
	
	repeat with trackInfo in trackData
		set trackid to track_id of trackInfo
		set trackContainerId to track_containerid of trackInfo
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
