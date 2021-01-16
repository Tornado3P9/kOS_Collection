//landing.ks
function main {
  CLEARSCREEN.
  print "started return maneuver".
  doLanding().
  print "script exited.".
}

function doLanding {
  lock steering to retrograde.
  wait until SHIP:altitude < 75000.
  // Do reentry staging
  abort on.
  // lock steering to surface retrograde
  lock steering to retrograde.
  doParachute().
  // on touchdown do
  wait until VERTICALSPEED = 0.
  wait 5.
  unlock all.
}

function doParachute {
  wait until myAltitude < 2000.
  print "parachutes".
  set AG10 to True.
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
