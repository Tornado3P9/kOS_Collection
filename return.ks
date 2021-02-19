//landing.ks Reentry staging on AG10
function main {
  CLEARSCREEN.
  print "started return maneuver".
  lock steering to retrograde.
  print "waiting until altitude < 75Km".
  wait until SHIP:altitude < 75000.
  // Do reentry staging
  print "AG10 on: last staging before reentry".
  set AG10 to True.
  // lock steering to surface retrograde
  lock steering to SRFRETROGRADE.
  doParachute().
  unlock all.
  //wait until SHIP:STATUS = "LANDED".
  print "script exited.".
}

function doParachute {
  wait until myAltitude < 2000.
  print "parachutes".
  CHUTES ON.
}

// realAltitude = round(bounds_box:BOTTOMALTRADAR, 1).
// ALT:RADAR
function myAltitude {
    if Ship:GeoPosition:TerrainHeight > 0{
	    set SurfaceHeight to Ship:GeoPosition:TerrainHeight.
    } else {
      set SurfaceHeight to 0.
    }
    return Ship:Altitude - SurfaceHeight.
}

main().
