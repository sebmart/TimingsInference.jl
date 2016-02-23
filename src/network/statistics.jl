###################################################
## statistics.jl
## Statistic computations on results (errors...)
###################################################


"""
    `tripsRMS`: compute standard deviation of timings error percentage
    - `timings`: timing reference
    - `trips` : list of trip data
"""
function tripsRMS(timings::NetworkTimings, trips::Vector{NetworkTrip})
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
    `tripsBias`: compute bias between trimings and trips
    - `timings`: timing reference
    - `trips` : list of trip data
"""
function tripsBias(timings::NetworkTimings, trips::Vector{NetworkTrip})
    tt = getPathTimes(timings)
    bias = 0.
    for t in trips
        bias += tt[t.orig, t.dest] - t.time
    end
    return bias/length(trips)
end

"""
    `allPathsRMS`: compute standard deviation of timings error percentage for all paths
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function allPathsRMS(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
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
    `roadTimeRMS`: compute standard deviation of road time error percentage
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function roadTimeRMS(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
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