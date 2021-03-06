###################################################
## network/tools/speeds.jl
## tools related to speed computations in the network
###################################################

"""
    `typicalSpeeds` : compute an array of typical speeds for each road-type,
    given network data
    Just iterate the iterative constant speeds method method to convergence
    Speeds are in meters per second
"""
function typicalSpeeds(pb::NetworkData;
                       uniqueSpeed=false,
                       maxTrips=100_000, solverargs...)
    speeds = Float64[]
    times = spzeros(Float64, nv(pb.network.graph), nv(pb.network.graph))

    initialTimes = randomTimes(pb.network);

    s = LimitedPaths(pb, initialTimes, pathsPerTrip = 1, maxTrip=maxTrips)

    logError = Inf
    newLogError = nwTripsLogError(s.timings, pb)
    while newLogError < logError
        # get the speeds
        speeds = constantSpeedSolver(s, uniqueSpeed=uniqueSpeed; solverargs...)
        # compute the times
        times = fixedSpeedTimes(pb.network,speeds)
        # update the state
        updateState!(s, times)

        # compute new error
        logError = newLogError
        newLogError = nwTripsLogError(s.timings, pb)
    end
    println("\n==============================================")
    println("Speeds converged, final error = $(newLogError)")
    return speeds
end
