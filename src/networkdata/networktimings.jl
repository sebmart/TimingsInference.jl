###################################################
## networktimings.jl
## Representing timing data in the network
###################################################

"""
    Represents the data about the trip orig=>dest in the network
"""
immutable NetworkTrip
    orig::Int
    dest::Int
    time::Float64
    count::Int
end

"""
    `NetworkData`
    Represent all data to use for timings inference in Network
"""
type NetworkData
    "The city routing network"
    network::Network
    "The trips data"
    trips::Vector{NetworkTrip}
    "lower bounds on roads timing (maximum speed)"
    minTimes::AbstractArray{Float64,2}
end


"""
    Contains timings from anywhere to anywhere in a network
    - represents a solution to a NetworkData problem
    - for now, just corresponds to RoutingPaths object
"""
typealias NetworkTimings RoutingPaths


function Base.show(io::IO, t::NetworkTrip)
    print(io,"$(t.orig)=>$(t.dest), n=$(t.count), t=$(t.time) seconds")
end

function Base.show(io::IO, n::NetworkData)
    println(io,"NetworkData: trip information in network")
    ntrips = length(n.trips)
    nrides = sum([t.count for t in n.trips])
    println(io,"$ntrips trips, $nrides rides")
end
