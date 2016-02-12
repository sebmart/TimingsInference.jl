###################################################
## statistics.jl
## Statistic computations on results (errors...)
###################################################


"""
    `tripsStd`: compute standard deviation of timings error percentage
    - `timings`: timing reference
    - `trips` : list of trip data
    - `weighted`: average per ride and not per trip
"""
function tripsStd(timings::NetworkTimings, trips::Vector{NetworkTrip})
    tt = getPathTimes(timings)
    error = 0.
    for t in trips
        error += ((t.time - tt[t.orig,t.dest])/t.time)^2
    end
    return sqrt(error/length(trips))
end

"""
    `tripsMAE`: compute Mean Absolute Error percentage between timings and trips
    - `timings`: timing reference
    - `trips` : list of trip data
    - `weighted`: average per ride and not per trip
"""
function tripsMAE(timings::NetworkTimings, trips::Vector{NetworkTrip})
    tt = getPathTimes(timings)
    error = 0.
    for t in trips
        error += abs(t.time - tt[t.orig,t.dest])/t.time
    end
    return error/length(trips)
end

"""
    `allPathsStd`: compute standard deviation of timings error percentage for all paths
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function allPathsStd(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    tt1 = getPathTimes(timingsRef)
    tt2 = getPathTimes(timingsNew)

    res = ((tt1-tt2)./tt1).^2
    #remove NAN where o==d
    for i in 1:size(tt1)[1]
        res[i,i] = 0.
    end
    return sqrt(sum(res)/(length(tt1)-size(tt1)[1]))
end

"""
    `allPathsMAE`: compute Mean Absolute Error of timings percentage for all paths
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function allPathsMAE(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    tt1 = getPathTimes(timingsRef)
    tt2 = getPathTimes(timingsNew)

    res = abs(tt1-tt2)./tt1
    #remove NAN where o==d
    for i in 1:size(tt1)[1]
        res[i,i] = 0.
    end
    return sum(res)/(length(tt1)-size(tt1)[1])
end

"""
    `allPathsMAEByLength`: compute MAE of timings percentage for all paths, broken down by path length
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function allPathsMAEByLength(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    g = timingsRef.network.graph
    tt1 = getPathTimes(timingsRef)
    tt2 = getPathTimes(timingsNew)

    ub = [1, 2, 3, 5, 10, 15, 20, 1_000_000]
    errors = [0. for i=eachindex(ub)]
    nTrips = [0 for i=eachindex(ub)]

    for o in vertices(g), d in vertices(g)
        if o != d
            pathLength = length(getPath(timingsRef, o, d)) - 1
            idx = 1
            while pathLength > ub[idx]
                idx += 1
            end
            errors[idx] = (nTrips[idx] * errors[idx] + abs(tt1[o,d] - tt2[o,d])/tt1[o,d])/(nTrips[idx] + 1)
            nTrips[idx] += 1
        end
    end
    return ub, errors, nTrips
end

"""
    `roadTimeStd`: compute standard deviation of road time error percentage
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function roadTimeStd(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    g = timingsRef.network.graph
    t1 = timingsRef.times
    t2 = timingsNew.times
    error = 0.
    for o in vertices(g), d in out_neighbors(g,o)
        error += ((t1[o,d]-t2[o,d])/t1[o,d])^2
    end
    return sqrt(error/ne(g))
end



"""
    `roadTimeMAE`: compute Mean Absolute Error of road time error percentage
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function roadTimeMAE(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    g = timingsRef.network.graph
    t1 = timingsRef.times
    t2 = timingsNew.times
    error = 0.
    for o in vertices(g), d in out_neighbors(g,o)
        error += abs(t1[o,d]-t2[o,d])/t1[o,d]
    end
    return error/ne(g)
end
