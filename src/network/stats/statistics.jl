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
    times = timings.times
    error = 0.
    count = 0
    for t in trips
        if t.roadProj
            error += t.weight * log(t.time / (tt[t.orig[2], t.dest[1]] + t.orig[3] * times[t.orig[1], t.orig[2]] + t.dest[3] * times[t.dest[1], t.dest[2]]))^2
        else
            err = t.weight * log(t.time / tt[t.orig[2],t.dest[1]])^2
            if err < Inf
                error += err
            else
                count += 1
            end
        end
    end
    return error/(length(trips)-count)
end

"""
    `tripsLogBias`: compute log bias between trimings and trips
    - `timings`: timing reference
    - `trips` : list of trip data
"""
function tripsLogBias(timings::NetworkTimings, trips::Vector{NetworkTrip})
    tt = getPathTimes(timings)
    times = timings.times
    bias = 0.
    count = 0
    for t in trips
        if t. roadProj
            bias += t.weight * log(tt[t.orig[2], t.dest[1]] + t.orig[3] * times[t.orig[1], t.orig[2]] + t.dest[3] * times[t.dest[1], t.dest[2]]) - log(t.time)
        else
            err = t.weight * log(tt[t.orig[2], t.dest[1]]/t.time)
            if abs(err) < Inf
                error += err
            else
                count += 1
            end
        end
    end
    return bias/(length(trips) - count)
end

"""
    `allPathsLogError`: compute log timings error for all paths
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function allPathsLogError(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    tt1 = getPathTimes(timingsRef)
    tt2 = getPathTimes(timingsNew)

    res = log(tt1./tt2).^2
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

    res = log(tt2./tt1)
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
        error += log(t1[o,d]/t2[o,d])^2
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
        error += log(t2[o,d]/t1[o,d])
    end
    return error/ne(g)
end

"""
    `nwTripsLogError`: compute log error on NetworkTrips inside NetworkData
"""
nwTripsLogError(timings::NetworkTimings, nd::NetworkData) = tripsLogError(timings, nd.trips)

"""
    `nwTripsLogBias`: compute log bias on NetworkTrips inside NetworkData
"""
nwTripsLogBias(timings::NetworkTimings, nd::NetworkData) = tripsLogBias(timings, nd.trips)

"""
    `tripsRealLogError` : computes log error on trips using their real times as computed from timingsRef
    Used to see if method denoises input data.
"""
function tripsRealLogError(timingsRef::NetworkTimings, timingsNew::NetworkTimings, trips::Vector{NetworkTrip})
    tt1 = getPathTimes(timingsRef)
    times1 = timingsRef.times
    tt2 = getPathTimes(timingsNew)
    times2 = timingsNew.times
    error = 0.
    count = 0
    for t in trips
        if t.roadProj
            error += log((tt1[t.orig[2], t.dest[1]] + t.orig[3] * times1[t.orig[1], t.orig[2]] + t.dest[3] * times1[t.dest[1], t.dest[2]])/(tt2[t.orig[2], t.dest[1]] + t.orig[3] * times2[t.orig[1], t.orig[2]] + t.dest[3] * times2[t.dest[1], t.dest[2]]))^2
        else
            err = log(tt1[t.orig[2],t.dest[1]] / tt2[t.orig[2],t.dest[1]])^2
            if err < Inf
                error += err
            else
                count += 1
            end
        end
    end
    return error/(length(trips)-count)
end

"""
    `tripsRealLogBias` : computes log bias on trips using their real times as computed from timingsRef
    Used to see if method denoises input data. Bias is (predicted - real).
"""
function tripsRealLogBias(timingsRef::NetworkTimings, timingsNew::NetworkTimings, trips::Vector{NetworkTrip})
    tt1 = getPathTimes(timingsRef)
    times1 = timingsRef.times
    tt2 = getPathTimes(timingsNew)
    times2 = timingsNew.times
    error = 0.
    count = 0
    for t in trips
        if t.roadProj
            error += log(tt2[t.orig[2], t.dest[1]] + t.orig[3] * times2[t.orig[1], t.orig[2]] + t.dest[3] * times2[t.dest[1], t.dest[2]]) - log(tt1[t.orig[2], t.dest[1]] + t.orig[3] * times1[t.orig[1], t.orig[2]] + t.dest[3] * times1[t.dest[1], t.dest[2]])
        else
            err = log(tt1[t.orig[2],t.dest[1]] / tt2[t.orig[2],t.dest[1]])
            if abs(err) < Inf
                error += err
            else
                count += 1
            end
        end
    end
    return error/(length(trips)-count)
end

"""
    `networkTripsRealLogError`: compute log error on NetworkTrips inside NetworkData
"""
nwTripsRealLogError(timingsRef::NetworkTimings, timingsNew::NetworkTimings, nd::NetworkData) = tripsRealLogError(timingsRef, timingsNew, nd.trips)

"""
    `networkTripsRealLogBias`: compute log bias on NetworkTrips inside NetworkData
"""
nwTripsRealLogBias(timingsRef::NetworkTimings, timingsNew::NetworkTimings, nd::NetworkData) = tripsRealLogBias(timingsRef, timingsNew, nd.trips)
