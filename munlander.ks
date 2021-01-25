// LANDER.KS -- An automated landing script.

// Recommended that you test your lander on the ground with a script that
// just prints ALT:RADAR to the terminal.
parameter SHIP_RADAR_HEIGHT is 3.75.
print "SHIP_RADAR_HEIGHT is " + SHIP_RADAR_HEIGHT.
print " ".

// PHASE 1: Point the right way!

PRINT "SETTING SAS".
sas on.
WAIT 0.0001.
SET SASMODE TO "RETROGRADE".
WAIT 3.

// PHASE 2: Kill our horizontal velocity (surface speed)

PRINT "KILLING HORIZONTAL VELOCITY".
UNTIL SHIP:GROUNDSPEED < 25 {
	LOCK THROTTLE TO 1.
	WAIT 0.01.
}

LOCK THROTTLE TO 0.


// PHASE 3: Gentle (we hope) landing!

PRINT "STARTING DESCENT LOGIC".
SET DESIREDVEL TO 200.
SET T TO 0.
LOCK THROTTLE TO T.

// Loop until we're two meters above the ground.
UNTIL ALT:RADAR < SHIP_RADAR_HEIGHT+2 {

	// This part can be replaced with a formula.
	if( ALT:RADAR < 25 ) {
		SET DESIREDVEL TO 2.
		// Change SAS mode so it doesn't go nuts when we touchdown.
		SET SASMODE TO "STABILITYASSIST".
	}
	else if( ALT:RADAR < 50 ) {
		SET DESIREDVEL TO 5.
	}
	else if( ALT:RADAR < 100 ) {
		SET DESIREDVEL TO 10.
	}
	else if( ALT:RADAR < 500 ) {
		SET DESIREDVEL TO 25.
	}
	else if( ALT:RADAR < 1000 ) {
		SET DESIREDVEL TO 50.
	}
	else if( ALT:RADAR < 3000 ) {
		SET DESIREDVEL TO 100.
	}

	// This part can be replaced by a PID Controller
	if( SHIP:VELOCITY:SURFACE:MAG > DESIREDVEL ) {
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

PRINT "KILLING ENGINES".
LOCK THROTTLE TO 0.
WAIT 3.
UNLOCK STEERING.
UNLOCK THROTTLE.
