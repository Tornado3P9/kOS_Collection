parameter shipheight is 3.88, deorbit is True. //shipheight is the radar altitude when landed with legs extended.

set radarOffset to 40 + shipheight. //first hold at 40m above ground
lock trueRadar to alt:radar - radarOffset. //suicide burn calculation...
lock g to constant:g * body:mass / body:radius^2.
lock maxDecel to (ship:availablethrust / ship:mass) - g.
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).
lock idealThrottle to stopDist / trueRadar.
lock impactTime to trueRadar / abs(ship:verticalspeed).

function main {
  clearscreen. SAS off.
  if deorbit { killHorizontalVel(). }
  //if mnv { execDeorbitManeuver(). }
  suicide().
  land().
  print "script exited.".
}

function killHorizontalVel {
  RCS on.
  print "KILLING HORIZONTAL VELOCITY".
  set steering to retrograde. wait 3. //steering should already be at retrograde before exec script!
  UNTIL SHIP:GROUNDSPEED < 15 {
  	LOCK THROTTLE TO 1.
  	WAIT 0.01.
  }
  LOCK THROTTLE TO 0.
}

function suicide {
  RCS on.
  lock steering to srfretrograde.
  print "waiting until radar < stopdistance".

  WAIT UNTIL trueRadar < stopDist. //suicide burn starts here
    lock throttle to idealThrottle.
    when impactTime < 3.5 then {gear on.}
  	print "Performing hoverslam".

  WAIT UNTIL ship:verticalspeed > -1.
  lock steering to lookDirUp( up:forevector, ship:facing:topvector ).
}

function land {
  set T to 0.1. lock throttle to T.
  print "Performing final landing".

  until SHIP:STATUS = "LANDED" {
    if( SHIP:verticalspeed < -1 ) {
      SET T TO MIN(1, T + 0.01).
    }
    else {
      SET T TO MAX(0, T - 0.1).
    }
    // If we're going up, something isn't quite right -- make sure to kill the throttle.
    if(SHIP:VERTICALSPEED > 0) {
      SET T TO 0.
    }
    WAIT 0.001.
  }

  set ship:control:pilotmainthrottle to 0. RCS off. SAS on.
}

main().
