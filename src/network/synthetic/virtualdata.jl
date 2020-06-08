###################################################
## network/tools/virtualdata.jl
## generate "virtual" network data
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
            push!(trips, NetworkTrip((orig,orig,0.),(dest,dest,0.),time,count,false))
        end
    end
    return NetworkData(t.network,trips, maxSpeedTimes(t.network))
end

"""
    `simpleVirtualData`
    generates random rides in a network, one per selected OD, with a given expected
    multiplicative log error.
    parameters:
    - `t` is the timings object representing timings expectation
    - N is the number of OD that we will generate a ride on.
    - logVariance is the multiplicative variance of the data from the truth.

    rides must be longer than a 30s to be taken into account

"""
function simpleVirtualData(t::NetworkTimings, N::Int, logStd::Float64)
    nNodes = nv(t.network.graph)
    allRides = vec([(o,d) for o in 1:nNodes, d in 1:(nNodes -1)])
    shuffle!(allRides)
    selectedRides = allRides[1:N]
    for (i, (o,d)) in enumerate(selectedRides)
        if o == d
            selectedRides[i] = (o, nNodes)
        end
    end

    tt = getPathTimes(t)

    trips = NetworkTrip[]
    # subset rides

    for (o,d) in selectedRides
        realLogTime = log(tt[o,d])
        noisyLogTime = rand(Normal(realLogTime, logStd))
        push!(trips, NetworkTrip((o,o,0.),(d,d,0.),exp(noisyLogTime),1.,false))
    end
    return NetworkData(t.network,trips, maxSpeedTimes(t.network))
end

"""
    `perfectVirtualData`
    generates rides in a network
    parameters:
    - `t` is the timings object representing timings
    Rides are only created if travel time exceeds minTripTime
"""
function perfectVirtualData(t::NetworkTimings, minTripTime::Float64=30.)
    g = t.network.graph
    trips = NetworkTrip[]
    tt = getPathTimes(t)
    for orig in 1:nv(g), dest in 1:nv(g)
        if tt[orig, dest] > minTripTime
            push!(trips, NetworkTrip((orig, orig, 0.), (dest, dest, 0.), tt[orig,dest], 1., false))
        end
    end
    return NetworkData(t.network, trips, maxSpeedTimes(t.network))
end
