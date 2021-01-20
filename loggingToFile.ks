//logger
clearscreen.
print "Attempting log" at (0,15).
set toLog to "X,Y,Z".
set difference to 0.001.
set lastLat to latitude + difference + difference.
set lastLong to longitude + difference + difference.

set shipHeight to 1.27. //input your ships height (alt:radar while on ground)

until 0 {
	set curAlt to altitude - (alt:radar - shipHeight). //should have named this ground elevation!
	if alt:radar = -1 { set curAlt to 0. }. //for when alt:radar bugs out...not sure why
	set curLat to latitude.
	set curLong to longitude.
	print altitude + " - (" + alt:radar + " - " + shipHeight + ")  " at (15,3).
	print "ELEVATION = " + curAlt + " m        " at (0,4).
	print "LAT       = " + curLat + " degrees  " at (0,6).
	print "LONG      = " + curLong + " degrees  " at (0,7).
	if abs(lastLat - curLat) > difference or abs(lastLong - curLong) > difference {
		set toLog to curLat + "," + curLong + "," + curAlt.
		print "Logging Active    " at (0,15).
		print "toLog     = " + toLog + "     " at (0,9).
		log toLog to logfile.
		print "Last log print: " + missiontime + "    " at (0,20).
		set lastLat to curLat.
		set lastLong to curLong.
	}.
	wait 0.5.
}.
