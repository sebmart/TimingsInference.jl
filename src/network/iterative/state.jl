###################################################
## network/iterative/state.jl
## Different iterative procedures
###################################################

"""
    `IterativeState`
    Abstract type, represents all information of a state of path/timingscomputation
    in the iterative process
    Must contain:
    - `data::NetworkData`          timing data in the network
    - `timings::NetworkTimings`    the current timings solution
    - `trips::Vector{NetworkTrip}` trips that we currently optimize on
    - `paths::Vector{Vector{Vector{Int}}}` path subset for each current trip datapoint
    Must implement:
    - `updateState!` updates the state when new link-times are computed
"""
abstract IterativeState


function Base.show(io::IO, s::IterativeState)
    typeName = split(string(typeof(s)),".")[end]
    nTrips = length(s.trips)
    nPaths = sum([length(paths) for paths in s.paths])
    mae = tripsMAE(s.timings, s.trips)
    println(io,"Iterative heuristic: $(typeName)")
    println(io,"Optimizing on $nTrips trips and $nPaths paths")
    @printf(io,"MAE on current trips: %.2f%%\n", mae*100)
end

NetworkTimings(it::IterativeState) = it.timings

"""
    `doIteration!`, shortcut to update state with optimizer's output
"""
function doIteration!(it::IterativeState; method::AbstractString="lp2", solverArgs...)
    if method=="lp"
        updateState!(it, lpTimes(it, solverArgs...))
    elseif method=="lp2"
        updateState!(it, lp2Times(it, solverArgs...))
    elseif method=="mip"
        updateState!(it, mipTimes(it, solverArgs...))
    elseif method == "heuristic"
        updateState!(it, heuristicTimes(it))
    else
        error("Unknown optimizer")
    end
    return it
end
