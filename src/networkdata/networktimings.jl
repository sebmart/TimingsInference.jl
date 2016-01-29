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
    weight::Float64
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

NetworkData(n::Network, trips::Vector{NetworkTrip}) = NetworkData(n, trips, maxSpeedTimes(n))


"""
    Contains timings from anywhere to anywhere in a network
    - represents a solution to a NetworkData problem
    - for now, just corresponds to RoutingPaths object
"""
typealias NetworkTimings RoutingPaths


function Base.show(io::IO, t::NetworkTrip)
    @printf(io,"%d=>%d, w=%.2f, t=%.1fs",t.orig,t.dest,t.weight,t.time)
end

function Base.show(io::IO, n::NetworkData)
    density = 100*length(n.trips)/((nv(n.network.graph)-1)*nv(n.network.graph))
    println(io,"NetworkData: trip information in network")
    @printf(io,"%d trips (%.2f%% density)",length(n.trips), density)
end
