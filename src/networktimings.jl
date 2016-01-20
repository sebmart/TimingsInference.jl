###################################################
## networktimings.jl
## Representing timing data in the network
###################################################

"""
    `NetworkData`
    Represent all data to use for timings inference in Network
"""
type NetworkData
    "The city routing network"
    network::RoutingNetwork
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

"""
    Represents the data about the trip orig=>dest in the network
"""
immutable NetworkTrip
    orig::Int
    dest::Int
    time::Float64
    count::Int
end
