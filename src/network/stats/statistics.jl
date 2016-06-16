###################################################
## network/stats/statistics.jl
## Statistic computations on results (errors...)
###################################################

"""
    `tripsLogError`: compute log timings error
    - `timings`: timing reference
    - `trips` : list of trip data
"""
function tripsLogError(timings::NetworkTimings, trips::Vector{NetworkTrip})
    tt = getPathTimes(timings)
    error = 0.
    for t in trips
        error += abs(log(t.time / tt[t.orig,t.dest]))
    end
    return error/length(trips)
end

"""
    `tripsLogBias`: compute log bias between trimings and trips
    - `timings`: timing reference
    - `trips` : list of trip data
"""
function tripsLogBias(timings::NetworkTimings, trips::Vector{NetworkTrip})
    tt = getPathTimes(timings)
    bias = 0.
    for t in trips
        bias += log(tt[t.orig, t.dest]) - log(t.time)
    end
    return bias/length(trips)
end

"""
    `allPathsLogError`: compute log timings error for all paths
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function allPathsLogError(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    tt1 = getPathTimes(timingsRef)
    tt2 = getPathTimes(timingsNew)

    res = abs(log(tt1./tt2))
    #remove NAN where o==d
    for i in 1:size(tt1)[1]
        res[i,i] = 0.
    end
    return sum(res)/(length(tt1)-size(tt1)[1])
end

"""
    `allPathsLogBias`: compute log bias of timings for all paths
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function allPathsLogBias(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    tt1 = getPathTimes(timingsRef)
    tt2 = getPathTimes(timingsNew)

    res = log(tt2)-log(tt1)
    #remove NAN where o==d
    for i in 1:size(tt1)[1]
        res[i,i] = 0.
    end
    return sum(res)/(length(tt1)-size(tt1)[1])
end

"""
    `roadTimeLogError`: compute log road time error 
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function roadTimeLogError(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    g = timingsRef.network.graph
    t1 = timingsRef.times
    t2 = timingsNew.times
    error = 0.
    for o in vertices(g), d in out_neighbors(g,o)
        error += abs(log(t1[o,d]/t2[o,d]))
    end
    return error/ne(g)
end

"""
    `roadTimeLogBias`: compute log bias of road times
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function roadTimeLogBias(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    g = timingsRef.network.graph
    t1 = timingsRef.times
    t2 = timingsNew.times
    error = 0.
    for o in vertices(g), d in out_neighbors(g,o)
        error += log(t2[o,d])-log(t1[o,d])
    end
    return error/ne(g)
end

"""
    `networkTripsLogError`: compute log error on NetworkTrips inside NetworkData
"""
networkTripsLogError(timings::NetworkTimings, nd::NetworkData) = tripsLogError(timings, nd.trips)

"""
    `networkTripsLogBias`: compute log bias on NetworkTrips inside NetworkData
"""
networkTripsLogBias(timings::NetworkTimings, nd::NetworkData) = tripsLogBias(timings, nd.trips)
