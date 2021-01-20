parameter radarOffset is 5.2.//the radar altitude when landed with the legs extended. Test before!!
print "radarOffset is " + radarOffset.

clearscreen.
print "suicide burn test v0.1".
//parameter landingsite is latlng(-0.0556882365026111,-74.5090489030054).//Input the landing latlng() here
lock trueRadar to alt:radar - radarOffset.//this is all the suicide burn calculation
lock g to constant:g * body:mass / body:radius^2.
lock maxDecel to (ship:availablethrust / ship:mass) - g.
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).
lock idealThrottle to stopDist / trueRadar.
lock impactTime to trueRadar / abs(ship:verticalspeed).

SAS off.
RCS on.
lock steering to srfretrograde.

wait until alt:radar < 3000.
  print "3000".
  when impactTime < 5.5 then {gear on.} //gear deployment variable, change it to whatever you'd like.

WAIT UNTIL trueRadar < stopDist. //suicide burn starts here
  lock throttle to idealThrottle.
	print "Performing hoverslam".

WAIT UNTIL ship:verticalspeed > -0.1. //there you go, landed.
  print "The Falcon has landed".
	set ship:control:pilotmainthrottle to 0.
	RCS off.
  SAS on.
