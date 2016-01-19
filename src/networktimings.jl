###################################################
## networktimings.jl
## Representing timing data in the network
###################################################

"""
    Contains timings from anywhere to anywhere in a network
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
