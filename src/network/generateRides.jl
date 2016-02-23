###################################################
## generateRides.jl
## generate "virtual" network ride data
###################################################

"""
    `noisyVirtualData`
    generates random rides in a network
    parameters:
    - `t` is the timings object representing timings expectation
    - `density` is the density of rides in the Graph (1.0 are all possible rides)
    - `frequency` is the average number of datapoints from one orig=>dest (>1)
    - optional parameter: `timeStd` is the standard deviation for a "one minute" ride (in seconds)

    rides must be longer than a 30s to be taken into account

    each timing is an exp variable, the number of rides is Geometric
"""
function noisyVirtualData(t::NetworkTimings, density::Float64=0.2, frequency::Float64=2.;
                          timeStd::Float64 = 20.)
    g = t.network.graph
    trips = NetworkTrip[]
    # subset rides
    tt = getPathTimes(t)
    if frequency <= 1.
        error("frequency must be >1")
    end
    geo = Geometric(1/frequency)
    for orig in 1:nv(g), dest in 1:nv(g)
        if rand() <= density && tt[orig,dest] >= 30.
            count = rand(geo) + 1.
            time  = max(20.,rand(Normal(tt[orig,dest],timeStd*sqrt(tt[orig,dest]/(count*60.)))))
            push!(trips, NetworkTrip(orig,dest,time,count))
        end
    end
    return NetworkData(t.network,trips, maxSpeedTimes(t.network))
end
