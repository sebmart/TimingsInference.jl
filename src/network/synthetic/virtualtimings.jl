###################################################
## network/tools/virtualtimings.jl
## Create virtual timings in a network
###################################################

"""
    `roadTypeTimings`
    - simplest version of road timings
    - returns a timing object with a constant speed for each road type
"""
function roadTypeTimings(n::Network)
    # Timings are 60% of maximum speed
    times = maxSpeedTimes(n) / 0.6
    return NetworkTimings(n, times)
end

"""
    `randomTimings`
    - returns a timing object with every edge having a randomly selected speed between 0 and 130 km/h
"""
function randomTimings(n::Network)
    times = randomTimes(n)
    return NetworkTimings(n, times)
end

"""
    `maxSpeedTimes`
    - returns road times corresponding to maximum allowed speed (sparse array)
    - `maxspeed`: km/h maximum speeds for each road-type
"""
function maxSpeedTimes(n::Network; maxspeed::Vector{Float64} = [130.,110.,90.,50.,50.,20.,0.,0.])
    g = n.graph
    times = spzeros(nv(g),nv(g))
    for ((o,d),r) in n.roads
        times[o,d] = 3.6*r.distance/maxspeed[r.roadType]
    end
    return times
end

"""
    `uniformTimes`
    - returns road times corresponding to constant speed (sparse array)
    - `speed` in km/h
"""
function uniformTimes(n::Network, speed::Float64=90.)
    g = n.graph
    times = spzeros(nv(g),nv(g))
    for ((o,d),r) in n.roads
        times[o,d] = 3.6*r.distance/speed
    end
    return times
end

"""
    `randomTimes`
    - returns road times corresponding to random speed (sparse array) between 0 and 130 km/h
"""
function randomTimes(n::Network)
    srand()
    g = n.graph
    times = spzeros(nv(g), nv(g))
    for ((o,d), r) in n.roads
        times[o,d] = 3.6 * r.distance / (rand() * 130)
    end
    return times
end