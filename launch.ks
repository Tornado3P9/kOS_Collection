//launch.ks
// SWITCH TO 1.
// COPYPATH("0:launch", "").
// RUN launch. // RUNPATH("launch"). // runpath("launch",90,90000,1). // run launch(90,90000,1).
parameter compass is 90, finalApoapsis is 85000, pitchFactor is 0.4.

function main {

  CLEARSCREEN.
  print "compass heading is " + compass + "°".
  print "finalApoapsis is " + finalApoapsis + "m".
  print "pitchFactor is " + pitchFactor.

  doLaunch().
  doAscent().
  until apoapsis > finalApoapsis {
    doAutoStage().
  }
  doShutdown().
  doCirculate().

  print "program exited.".
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
  lock throttle to 1.
  doSafeStage().
  lock steering to heading(90, 90, 270).
}

function doAscent {
  set targetPitch to 90.
  set targetDirection to compass.
  set targetRoll to 0.
  wait until verticalSpeed >= 60.
  print "pitching maneuver started.".
  until targetPitch < (88.963 - 1.03287 * alt:radar^0.409511) {
    set targetPitch to targetPitch - pitchFactor.
    lock steering to heading(targetDirection, targetPitch, targetRoll).
    wait 0.5.
  }
  lock targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.
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

function doShutdown {
  lock throttle to 0.
  // lock steering to prograde + R(0,0,270).
  lock steering to prograde.
  print "shutting down and holding prograde.".
}

// CIRCULATE:

function doCirculate {
  until ship:altitude > 70005 {
    PRINT "SHIP:APOAPSIS " + ROUND(SHIP:APOAPSIS,0) AT (0,18).
    PRINT "SHIP:PERIAPSIS " + ROUND(SHIP:PERIAPSIS,0) AT (0,19).
  }
  // wait until ship:altitude > 70005.
  print "Calc. Circulation Maneuv.".
  set burnTime to getManeuverBurnTime().
  // Set the start and end times.
  set start_time to abs(time:seconds + eta:apoapsis - (burnTime / 2)).
  set end_time to abs(time:seconds + eta:apoapsis + (burnTime / 2)).
  WAIT UNTIL TIME:SECONDS >= start_time.
  LOCK throttle TO 1.
  print "burn started.".
  UNTIL TIME:SECONDS >= end_time {
    // doAutoStage() mit kleiner Aenderung
    if not(defined oldThrust) {
      declare global oldThrust to ship:availablethrust.
    }
    if ship:availableThrust < (oldThrust - 10) {
      set end_time to end_time + 2. // added because of lost time while staging
      doSafeStage(). wait 1.
      set oldThrust to ship:availablethrust.
    }
  }
  LOCK throttle TO 0.
  print "burn finished.".
  unlock all.
  SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}

function getManeuverBurnTime {
  // local my is constant:G * Kerbin:Mass.               // 3531.6. Km^3/s^2
  local my is 3531.6.
  local r is 600 + (finalApoapsis / 1000).                     // z.B. 85Km (600Km = Kerbin Radius)
  local a is (ship:apoapsis + ship:periapsis + 1200000) / 2000.    // Semimajor Axis
  local Vf is sqrt(my / r).                           // The Velocity of any object in that orbit.
  local Vi is sqrt(-(my / a) + ((2 * my) / r)).       // The Velocity of any object in that orbit.
  local dV is (Vf - Vi) * 1000.                       // Velocity-Difference from one orbit to the other.
  
  print "calculated dV: " + CEILING(dV,2) + "m/s.".              // Calculated using VisVivaEquation.
  local g0 is 9.80655.
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:IGNITION and not en:FLAMEOUT {
      set isp to isp + (en:isp * (en:availablethrust / ship:availablethrust)).
    }
  }

  local mf is ship:mass / constant():e^(dV / (isp * g0)).
  local fuelFlow is ship:availablethrust / (isp * g0).
  local t is abs((ship:mass - mf) / fuelFlow).

  print "maneuverBurnTime: " + CEILING(t,2) + "s.".
  return t.
}

main().