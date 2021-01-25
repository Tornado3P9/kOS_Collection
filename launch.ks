//launch.ks
// SWITCH TO 1. -> COPYPATH("0:launch", ""). -> RUN launch.
// or else: RUNPATH("launch"). // runpath("launch",90,90000,True). // run launch(90,90000,True).
// AG5 (Action Group 5) is Fairing or Escape Tower
parameter compass is 90, finalApoapsis is 80000, fairingOrEscape is True.

SET targetPitch TO 90. //LAUNCH
SET T TO 0. //LAUNCH
LOCK THROTTLE TO T. //LAUNCH
SET mnvTime TO 0. //CIRCULATE
SET throttleTime TO 0. //CIRCULATE

function main {

  CLEARSCREEN.
  print "compass heading is " + compass + "°".
  print "finalApoapsis is " + finalApoapsis + "m".
  print "fairingOrEscape on AG5 is " + fairingOrEscape.

  doLaunch().
  doAscent().
  until apoapsis > finalApoapsis {
    doAutoStage().
    if targetPitch < 1 {
      set targetPitch to 1.
    }
    doAutoThrottle().
  }
  doShutdown().
  doCirculate().
  print "script exited.".
}

// LAUNCH:

function doSafeStage {
  wait until stage:ready.
  stage.
  print "staging.".
}

function doLaunch {
  PRINT "Counting down:".
  FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1.
  }
  SET T TO 1. //THROTTLE
  doSafeStage().
  lock steering to heading(90, 90, 270).
}

function doAscent {
  set targetDirection to compass.
  set targetRoll to 0.
  wait until verticalSpeed >= 60.
  print "pitching maneuver started.".
  lock targetPitch to 1.92308E-8 * ship:altitude^2 - 0.00263462 * ship:altitude + 90.
  //lock targetPitch to 90 - 0.00178 * ship:altitude. //Linear
  lock steering to heading(targetDirection, targetPitch, targetRoll).
}

function doAutoStage {
  if not(defined oldThrust) {
    declare global oldThrust to ship:availablethrust.
  }
  if ship:availableThrust < (oldThrust - 10) {
    doSafeStage(). wait 1.
    set oldThrust to ship:availablethrust.
  }
}

function doAutoThrottle {
  if( ETA:APOAPSIS > 59 ) and (ALT:RADAR < 50000) {
    SET T TO MAX(0, T - 0.1). //THROTTLE
  }
  else {
    SET T TO MIN(1, T). //THROTTLE
  }
}

function doShutdown {
  lock throttle to 0.
  // lock steering to prograde + R(0,0,270).
  lock steering to prograde.
  print "shutting down and holding prograde.".
}

// CIRCULATE:

function doCirculate {
  wait until ship:altitude > 70005.
  if fairingOrEscape {
    PRINT "AG5 on.".
    set AG5 to True.
    WAIT 0.5.
  }
  set mnvDeltaV to maneuverDeltaV().
  // parameter utime, radial, normal, prograde.
  local mnv is node(TIME:SECONDS + ETA:APOAPSIS, 0, 0, mnvDeltaV).
  add mnv. //addManeuverToFlightPlan
  set mnvTime to maneuverBurnTime(mnv).
  set startTime to TIME:SECONDS + ETA:APOAPSIS - (mnvTime / 2).
  set throttleTime to startTime + mnvTime - 0.5.
  //warpto(startTime - 30).
  wait until time:seconds > startTime - 30.
  lock steering to mnv:burnvector.
  wait until time:seconds > startTime.
  SET T TO 1. //THROTTLE
  wait until isManeuverComplete(mnv).
  SET T TO 0. //THROTTLE
  remove mnv. //removeManeuverFromFlightPlan
  print "burn finished.".
  unlock all.
  SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}

function maneuverDeltaV {
  local kerbinRadius is Body:RADIUS.
  local my is constant:G * Kerbin:Mass.
  local r is SHIP:APOAPSIS + kerbinRadius.
  local a is Orbit:SEMIMAJORAXIS.
  local Vf is sqrt(my / r).  // The Velocity of any object in finalOrbit
  local Vi is sqrt(my * ((2/r) - (1/a))). // The Velocity at apoapsis
  local dV is Vf - Vi.  // Velocity-Difference from one orbit to the other.

  print "calculated dV: " + CEILING(dV,2) + "m/s.".
  return dV.
}

function maneuverBurnTime {
  parameter mnv.
  local dV is mnv:deltaV:mag.
  local g0 is 9.80665.
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:IGNITION and not en:FLAMEOUT {
      set isp to isp + (en:isp * (en:availablethrust / ship:availablethrust)).
    }
  }

  local mf is ship:mass / constant():e^(dV / (isp * g0)).
  local fuelFlow is ship:availablethrust / (isp * g0).
  local t is (ship:mass - mf) / fuelFlow. //maneuverBurnTime

  print "maneuverBurnTime: " + CEILING(t,2) + "s.".
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

main().
