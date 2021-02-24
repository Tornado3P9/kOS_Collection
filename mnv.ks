// MANEUVER:
set mnvTime to 0.
set throttleTime to 0.

function executeManeuverNode {
  local mnv is nextNode.
  set startTime to calculateStartTime(mnv).
  set throttleTime to startTime + mnvTime - 0.3.
  //warpto(startTime - 40). //your choice whether to uncomment or not
  wait until time:seconds > startTime - 30.
  lock steering to mnv:burnvector. //lockSteeringAtManeuverTarget
  wait until time:seconds > startTime.
  lock throttle to 1.
  wait until isManeuverComplete(mnv).
  lock throttle to 0.
  remove mnv. //removeManeuverFromFlightPlan
  print "script exited.".
}

function addManeuverToFlightPlan {
  parameter mnv.
  add mnv.
}

function calculateStartTime {
  parameter mnv.
  print "Node in: " + round(mnv:eta) + "s, DeltaV: " + round(mnv:deltav:mag) + "m/s.".
  set mnvTime to maneuverBurnTime(mnv).
  return time:seconds + mnv:eta - mnvTime / 2.
}

function maneuverBurnTime {
  parameter mnv.
  local dV is mnv:deltaV:mag.
  local g0 is ship:Body:MU.
  //print "Body g0 is: " + g0.
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:IGNITION and not en:FLAMEOUT {
      set isp to isp + (en:isp * (en:availablethrust / ship:availablethrust)).
    }
  }

  local mf is ship:mass / constant():e^(dV / (isp * g0)).
  local fuelFlow is ship:availablethrust / (isp * g0).
  local t is (ship:mass - mf) / fuelFlow.

  print "maneuverBurnTime: " + round(t) + "s.".
  return t.
}

function isManeuverComplete {
  parameter mnv.
  if time:seconds > throttleTime {
    lock throttle to 0.2.
  }
  if not(defined originalVector) or originalVector = -1 {
    declare global originalVector to mnv:burnvector.
  }
  if vAng(originalVector, mnv:burnvector) > 90 {
    declare global originalVector to -1.
    return true.
  }
  return false.
}

executeManeuverNode().
