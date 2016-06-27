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
    - `paths::Vector{Vector{Dict{Edge, Float64}}}` path subset for each current trip datapoint
    Must implement:
    - `updateState!` updates the state when new link-times are computed
"""
abstract IterativeState


function Base.show(io::IO, s::IterativeState)
    typeName = split(string(typeof(s)),".")[end]
    nTrips = length(s.trips)
    nPaths = sum([length(paths) for paths in s.paths])
    println(io,"Iterative heuristic: $(typeName)")
    println(io,"Optimizing on $nTrips trips and $nPaths paths")
end

NetworkTimings(it::IterativeState) = it.timings

"""
    `doIteration!`, shortcut to update state with optimizer's output
"""
function doIteration!(it::IterativeState; method::AbstractString="lp", velocityBound::Float64 = 0.1, solverArgs...)
    if method=="lp"
        updateState!(it, lpTimes(it, solverArgs...))
    elseif method=="fraclp"
        updateState!(it, fraclpTimes(it, solverArgs...))
    elseif method=="mip"
        updateState!(it, mipTimes(it, solverArgs...))
    elseif method == "heuristic"
        updateState!(it, heuristicTimes(it))
    elseif method == "socp"
        updateState!(it, socpTimes(it, solverArgs...))
    elseif method == "lpCo"
        updateState!(it, lpTimesContinuous(it, velocityBound, solverArgs...))
    elseif method == "socpCo"
        updateState!(it, socpTimesContinuous(it, velocityBound, solverArgs...))
    elseif method == "socpCo2"
        updateState!(it, socpTimesContinuous2(it, velocityBound, solverArgs...))
    else
        error("Unknown optimizer")
    end
    return it
end
