###################################################
## networktypes.jl
## Types representing network timings problem (NetworkData) and network timings estimates (Network Timings)
###################################################

"""
    Represents the data about the trip orig=>dest in the network
    Origin and destination are represented as (edge, weight) pairs for generality.
    If origin and destination are nodes, then the edge is just a loop from that node to that
    node, with weight 0. So a path from node 1 to node 5 will be indicated as
     (1,1,0.0) to (5,5,0.0)
"""
struct NetworkTrip
    "Origin edge and weight of that edge"
    orig::Tuple{Int,Int,Float64}
    "Destination edge and weight of that edge"
    dest::Tuple{Int,Int,Float64}
    "Travel time"
    time::Float64
    "Number of rides"
    weight::Float64
    "Boolean that identifies if trip results from road projection"
    roadProj::Bool
end
function Base.show(io::IO, t::NetworkTrip)
    if t.roadProj
        @printf(io,"(%d,%d)=>(%d,%d), w=%.1f, t=%.1fs",t.orig[1],t.orig[2],t.dest[1],t.dest[2],t.weight,t.time)
    else
        @printf(io,"%d=>%d, w=%.2f, t=%.1fs",t.orig[1],t.dest[1],t.weight,t.time)
    end
end

"""
    `NetworkData`
    Represent all data to use for timings inference in Network
"""
mutable struct NetworkData
    "The city routing network"
    network::Network
    "The trips data"
    trips::Vector{NetworkTrip}
    "lower bounds on roads timing (maximum speed)"
    minTimes::AbstractArray{Float64,2}
end

NetworkData(n::Network, trips::Vector{NetworkTrip}) = NetworkData(n, trips, maxSpeedTimes(n))

function Base.show(io::IO, n::NetworkData)
    density = 100*length(n.trips)/((nv(n.network.graph)-1)*nv(n.network.graph))
    println(io,"NetworkData: trip information in network")
    @printf(io,"%d trips (%.2f%% density)",length(n.trips), density)
end

"""
    Contains timings from anywhere to anywhere in a network
    - represents a solution to a NetworkData problem
    - for now, just corresponds to RoutingPaths object
    useful attributes:
    - `times` : link times
    - `pathTimes`: all timings
"""
const NetworkTimings = RoutingNetworks.RoutingPaths
