//launch.ks
// switch to 0. -> list. -> run launch(90,100000,True).
// or else: SWITCH TO 1. -> COPYPATH("0:launch", ""). -> RUN launch.
// RUNPATH("launch"). // runpath("launch",90,90000,True,-1). // run launch(90,90000,True,-1).
// also possible to only change the first ones: run launch(90,90000).
// AG5 (Action Group 5) is Fairing or Escape Tower
// throttleOfSecondStage is automaticly calculated if not specified at start (-1 means not specified)
parameter compass is 90, finalApoapsis is 80000, fairingOrEscape is True, throttleOfSecondStage is -1.

SET targetPitch TO 90. //LAUNCH
SET mnvTime TO 0. //CIRCULATE
SET throttleTime TO 0. //CIRCULATE

function main {

  displaySettings().
  armAG5Trigger().

  doLaunch().
  doAscent().
  until apoapsis > finalApoapsis {
    doAutoStage().
    if targetPitch < 3 {
      set targetPitch to 3.
    }
  }
  doShutdown().
  doCirculate().
  print "script exited.".
}

// function armAbort {
//   on ABORT {
//     lock THROTTLE to 0.
//     lock steering to prograde.
//     wait 0.5.
//     set AG9 to true. //abort actions work better on AG9
//     wait 5.
//     lock steering to retrograde.
//     RCS on.
//     set AG5 to true.
//     wait until ALT:RADAR < 2000.
//     print "parachutes".
//     CHUTES ON.
//     unlock all.
//     RCS off.
//     wait until 1 = 0. //script needs to be aborted with "STRG+C"
//   }
// }

function displaySettings {
  CLEARSCREEN.
  print "compass heading is " + compass + "°".
  print "finalApoapsis is " + finalApoapsis + "m".
  print "fairingOrEscape on AG5 is " + fairingOrEscape.
  if throttleOfSecondStage > 0 {print "throttleOfSecondStage is " + throttleOfSecondStage.}
  print " ".
}

function armAG5Trigger {
  if fairingOrEscape {
    WHEN ship:altitude > 70005 THEN {
      PRINT "AG5 on.".
      set AG5 to True.
    }
  }
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
  lock THROTTLE to 1.
  doSafeStage().
  lock steering to heading(90, 90, 270).
}

function doAscent {
  set targetDirection to compass.
  set targetRoll to 0.
  wait until verticalSpeed >= 60.
  print "pitching maneuver started.".
  //lock targetPitch to 1.92308E-8 * ship:altitude^2 - 0.00263462 * ship:altitude + 90.
  //lock targetPitch to 1.05884E-8 * ship:altitude^2 - 0.0020129 * ship:altitude + 90.0137.
  lock targetPitch to 1.48272E-8 * ship:altitude^2 - 0.00229755 * ship:altitude + 90.
  lock THROTTLE TO MAX(0.55, (1/90) * targetPitch).
  lock steering to heading(targetDirection, targetPitch, targetRoll).
}

function doAutoStage {
  if not(defined oldThrust) {
    declare global oldThrust to ship:availablethrust.
  }
  if ship:availableThrust < (oldThrust - 10) {
    doSafeStage().
    if throttleOfSecondStage > 0 {lock THROTTLE to throttleOfSecondStage.}
    wait 1.
    set oldThrust to ship:availablethrust.
  }
}

function doShutdown {
  lock THROTTLE to 0.
  // lock steering to prograde + R(0,0,270).
  lock steering to prograde.
  print "shutting down and holding prograde.".
}

// CIRCULATE:

function doCirculate {
  print "Starting circulation sequence:".
  wait until ship:altitude > 70005.
  WAIT 1.
  set mnvDeltaV to maneuverDeltaV().
  // parameter utime, radial, normal, prograde.
  local mnv is node(TIME:SECONDS + ETA:APOAPSIS, 0, 0, mnvDeltaV).
  add mnv. //addManeuverToFlightPlan
  set mnvTime to maneuverBurnTime(mnv).
  set startTime to TIME:SECONDS + ETA:APOAPSIS - (mnvTime / 2).
  set throttleTime to startTime + mnvTime - 0.3.
  //warpto(startTime - 40). //your choice whether to uncomment or not
  wait until time:seconds > startTime - 30.
  lock steering to mnv:burnvector.
  print "locking steering to maneuver target".
  wait until time:seconds > startTime.
  lock THROTTLE to 1.
  wait until isManeuverComplete(mnv).
  lock THROTTLE to 0.
  lock steering to prograde. //mnv:burnvector goes crazy at end of burn
  remove mnv. //removeManeuverFromFlightPlan
  print "burn finished.".
  print "waiting for steering to settle down a bit".
  WAIT 3.
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
  local g0 is constant:G * Kerbin:Mass. //Gravitational parameter of Kerbin
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:IGNITION and not en:FLAMEOUT {
      set isp to isp + (en:isp * (en:availablethrust / ship:availablethrust)).
    }
  }

  local mf is ship:mass / constant:e^(dV / (isp * g0)).
  local fuelFlow is ship:availablethrust / (isp * g0).
  local t is (ship:mass - mf) / fuelFlow. //maneuverBurnTime

  print "maneuverBurnTime: " + CEILING(t,2) + "s.".
  return t.
}

function isManeuverComplete {
  parameter mnv.
  if time:seconds > throttleTime {
    lock THROTTLE to 0.2.
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
