﻿
tell application "iTunes"
	set myTracks to {}
	set myAlbums to {}
	repeat with myTrack in selection
		if class of myTrack = file track then
			set mycontainer to container of myTrack
			set myalbum to album of myTrack
			set myartist to artist of myTrack
			--			set isMusicPlaylist to (special kind of container of myTrack = Music)
			set isMusicPlaylist to true
			if myalbum = "" then
				1 + 1
				--display dialog "Skipping track without an album name: " & name of myTrack
			else
				if myalbum is not in myAlbums and isMusicPlaylist then
					set end of myAlbums to myalbum
					set myAlbumTracks to (tracks of mycontainer whose album is myalbum and artist is myartist)
					if class of myAlbumTracks is not list then
						set myAlbumTracks to {myAlbumTracks}
					end if
					repeat with myAlbumTrack in myAlbumTracks
						--						set myAlias to location of myAlbumTrack
						--						set myPosixPath to POSIX path of myAlias
						set containerId to id of container of myAlbumTrack
						set trackNumber to track number of myAlbumTrack
						set trackartist to artist of myAlbumTrack
						if trackNumber = "" then
							set trackNumber to 1
						end if
						-- tracklocation:myPosixPath, 
						set trackData to {track_id:id of myAlbumTrack as number, track_artist:trackartist, track_album:myalbum, track_name:name of myAlbumTrack, track_number:track number of myAlbumTrack, track_containerid:containerId}
						set end of myTracks to trackData
					end repeat
				end if
			end if
		end if
	end repeat
end tell

tell application "System Events"
	set myPlist to make new property list item with properties {value:myTracks, kind:list}
end tell
return text of myPlist


