###################################################
## createtimings.jl
## Create timings given a network object
###################################################

"""
    `roadTypeTimings`
    - simplest version of road timings
    - returns a timing object with a constant speed for each road type
"""
function roadTypeTimings(n::RoutingNetwork)
    # Timings are 70% of maximum speed
    times = maxSpeedTimes(n) * 0.6
    return NetworkTimings(n, times)
end

"""
    `maxSpeedTimes`
    - returns road times corresponding to maximum allowed speed (sparse array)
"""
function maxSpeedTimes(n::RoutingNetwork)
    g = n.graph
    # speeds in km/h for each roadType
    maxspeed = [130.,110.,90.,50.,50.,20.,0.,0.]
    times = szeros(nv(g),nv(g))
    for ((o,d),r) in n.roads
        times[o,d] = 3.6*r.distance/maxspeed[r.roadType]
    end
    return times
end
