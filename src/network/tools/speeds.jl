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
                       maxTrips=100_000)
    speeds = Float64[]
    initialTimes = randomTimes(pb.network);

    s = LimitedPaths(pb, initialTimes, pathsPerTrip = 1, maxTrip=maxTrips)

    logError = Inf
    newLogError = nwTripsLogError(initialTimes, pb)
    while newLogError <= logError
        # get the speeds
        speeds = constantSpeedSolver(s, uniqueSpeed=uniqueSpeed)
        # compute the times
        times = spzeros(Float64, nv(g), nv(g))
        for i in vertices(g), j in out_neighbors(g,i)
            times[i,j] = roads[i, j].distance / speeds[roads[i ,j].roadType]
        end
        # update the state
        updateState!(s, times)

        # compute new error
        logError = newLogError
        newLogError = nwTripsLogError(times, pb)
    end
    println("\n==============================================")
    println("Speeds converged, final error = $(newLogError)")
    return speeds
end
