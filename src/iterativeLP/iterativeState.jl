###################################################
## iterativeState.jl
## Represents state information in iterative process
###################################################
"""
    IterativeState
    represents all information of a state of path/timings computation
    in the iterative process
"""
type IterativeState

    "network : the city routing network"
    network::RoutingNetwork

    "tripData : the available data in the network"
    tripData::Vector{NetworkTrip}

    "minTimes : lower bounds on roads timing (maximum speed)"
    minTimes::AbstractArray{Float64,2}

    "timings : current roadTimes and associated shortest paths"
    timings::NetworkTimings

    "paths : path subset for each trip datapoint"
    paths::Vector{Vector{Int}})

end
