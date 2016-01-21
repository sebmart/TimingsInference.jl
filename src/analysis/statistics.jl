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

"""
    `allPathsStd`: compute standard deviation of timings error percentage for all paths
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function allPathsStd(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    tt1 = getPathTimes(timingsRef)
    tt2 = getPathTimes(timingsNew)
    #remove trips where o==d
    return sqrt(sum(((tt1-tt2)./tt1).^2)/(length(tt1)-size(tt1)[1]))
end

"""
    `allPathsMAE`: compute Mean Absolute Error of timings percentage for all paths
    - `timingsRef`: reference times
    - `timingsNew`: times to compare with
"""
function allPathsMAE(timingsRef::NetworkTimings, timingsNew::NetworkTimings)
    tt1 = getPathTimes(timingsRef)
    tt2 = getPathTimes(timingsNew)
    #remove trips where o==d
    return sum(abs(tt1-tt2)./tt1)/(length(tt1)-size(tt1)[1])
end

"""
    `roadTimeStd`: compute standard deviation of road time error percentage
    - `timesRef`: reference times
    - `timesNew`: times to compare with
"""
function roadTimeStd(timesRef::AbstractArray{Float64,2}, timesNew::AbstractArray{Float64,2})
    return sqrt(sum(((timesRef-timesNew)./timesRef).^2)/nnz(timesRef))
end

roadTimeStd(t1::NetworkTimings, t2::NetworkTimings) = roadTimeStd(t1.times, t2.times)


"""
`roadTimeMAE`: compute Mean Absolute Error of road time error percentage
    - `timesRef`: reference times
    - `timesNew`: times to compare with
"""
function roadTimeMAE(timesRef::AbstractArray{Float64,2}, timesNew::AbstractArray{Float64,2})
    return sum(abs(timesRef-timesNew)./timesRef)/nnz(timesRef)
end

roadTimeMAE(t1::NetworkTimings, t2::NetworkTimings) = roadTimeMAE(t1.times, t2.times)
