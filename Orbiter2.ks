// Declaration of functions
function executenode{
    local mnv is list(time:seconds,0). // create a blank node
    list engines in myEngines. // creates list of engines on current ship
    for eng in myEngines {
        set isp to eng:isp. // sets isp to the isp of active engine
    }
    createnode(mnv). // calculates the circularisation maneuver and adds to map
    calcburntime(isp,circular).
    locknode(circular,burntime).
    burnnode(burntime).
}
function createnode {
    parameter mnv.
    wait until altitude > 70000.
    for stepsize in list (100,10,1){
        until false {
            local oldmnvecc is ecc(mnv).
            set mnv to improve(mnv,stepsize).
            if oldmnvecc <= ecc(mnv) {
                global circular to node(mnv[0], 0, 0, mnv[1]).
                add circular.
                break.
        }
    }
    }
}
function ecc { //lower ecc is better i.e. more circular
    parameter mnv.
    set mnvtest to node(mnv[0], 0, 0, mnv[1]).
    add mnvtest.
    set ecccalc to mnvtest:orbit:eccentricity.
    remove mnvtest.
    return ecccalc.
}
function improve{ //improve the current iteration of mnv which is input. return bestmnv.
    parameter mnv.
    parameter stepsize.
    local bestecc is ecc(mnv). // the initial best eccentricity is the base mnv
    local bestmnv is mnv. // the intial best maneuver is the base mnv
    //a way to include step size in calculations.
    local candidates is list().
    local index is 0.
    until index >= mnv:length {
        local incCandidate is mnv:copy().
        local decCandidate is mnv:copy().
        set incCandidate[index] to incCandidate[index]+stepsize.
        set decCandidate[index] to decCandidate[index]-stepsize.
        candidates:add(incCandidate).
        candidates:add(decCandidate).
        set index to index +1.
    }
    for possiblemnv in candidates { //for each of the items in the list.
        local possiblemnvecc is ecc(possiblemnv). //possible eccentricity is the output of ecc() function.
        if possiblemnv[0] < time:seconds {
            break.
        }
        else {
            if possiblemnvecc < bestecc {
            set bestecc to ecc(possiblemnv).
            set bestmnv to possiblemnv.
            }
        
        }
    }
    print bestmnv.
    return bestmnv.
}
function locknode {
    parameter circular,burntime.
    wait circular:eta - burntime/2-5.
    lock steering to circular:BURNVECTOR.
}
function calcburntime{
    parameter isp.
    parameter circular.
    set burntime to (ship:mass*isp*constant:g0 /ship:maxthrust)*(1 - constant:e^(-circular:deltav:mag/(isp*constant:g0))).
    print "The estimated burntime is " + ceiling(burntime,3) + " seconds".
    return burntime.
}
function burnnode{
    parameter burntime.
    wait 5.
    lock throttle to 1.0.
    wait burntime.
    lock throttle to 0.
    lock steering to prograde. 
    remove circular.
}
function orbitstats{
    if ship:apoapsis > 70000 and ship:periapsis > 70000{
        print "Orbit has been achieved".
        wait 1.
        print "Orbital parameters:".
        wait 1.
        print "Apoapsis: " + ceiling(orbit:apoapsis/1000,3) +"km".
        wait 1.
        print "Periapsis: " + ceiling(orbit:periapsis/1000,3) + "km".
        wait 1.
        print "Inclination: " + ceiling(orbit:inclination,3) + "°".
    } else{
        print "Orbit failure!".
    }  
}
function launch{
clearscreen. 
print "Launch in T-3".
set x to 3.
wait 1.
until x = 1 {
    set x to x-1.
    print x.
    wait 1.
}
print "Launch!".
lock throttle to 1.0.
stage.
}
function mainsteer{
    set tarbearing to 90.
    lock tarpitch to (85 - altitude^0.396).
    lock steering to heading (90,90).
    wait until altitude > 1000.
    lock steering to heading (tarbearing, tarpitch).
    wait until altitude > 10000.
    lock steering to prograde.
    wait until ship:apoapsis > 100000.
    lock throttle to 0.
}
function main{
    launch().
    mainsteer().
    executenode().
    orbitstats().
}
// Master programme
main().