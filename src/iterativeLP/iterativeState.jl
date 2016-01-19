###################################################
## iterativeState.jl
## Represents state information in iterative process
###################################################

"""
    `IterativeState`
    Abstract type, represents all information of a state of path/timings computation
    in the iterative process
    must contain:
    - `network`  the city routing network
    - `timings`  the current timings solution
    - `tripData` trips that we currently optimize on
    - `minTimes` lower bounds on roads timing (maximum speed)
    - `paths`    path subset for each current trip datapoint
    must implement
    - `updateState!` updates the state when new timings are computed

"""
abstract IterativeState

"""
    `StaticState`
     Iterative state optimizing on static data (do not add or remove datapoints, use them all)
"""
type StaticState <: IterativeState
    # inherited attributes
    network::RoutingNetwork
    trips::Vector{NetworkTrip}
    minTimes::AbstractArray{Float64,2}
    timings::NetworkTimings
    paths::Vector{Vector{Int}})

end

"""
    update paths of StaticState object given new timings
"""
function updateState!(s::StaticState, times::AbstractArray{Float64,2})

    #first, update the timings and compute shortest paths
    s.timings = NetworkTimings(s.network, times)

    

end
