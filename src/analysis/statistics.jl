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
function tripsStd(timings::NetworkTimings, trips::Vector{NetworkTrip};weighted=false)
    tt = getPathTimes(timings)
    error = 0.
    if weighted
        for t in trips
            error += ((t.time - tt[t.orig,t.dest])/t.time)^2
        end
        return sqrt(error/length(trips))
    else
        count = 0.
        for t in trips
            count += t.count
            error += t.count * ((t.time - tt[t.orig,t.dest])/t.time)^2
        end
        return sqrt(error/count)
end

"""
    `tripsMAE`: compute Mean Absolute Error percentage between timings and trips
    - `timings`: timing reference
    - `trips` : list of trip data
    - `weighted`: average per ride and not per trip
"""
function tripsMAE(timings::NetworkTimings, trips::Vector{NetworkTrip};weighted=false)
    tt = getPathTimes(timings)
    error = 0.
    if weighted
        for t in trips
            error += abs(t.time - tt[t.orig,t.dest])/t.time)
        end
        return error/length(trips)
    else
        count = 0.
        for t in trips
            count += t.count
            error += t.count * abs(t.time - tt[t.orig,t.dest])/t.time)
        end
        return error/count
end
