###################################################
## network/iterative/state.jl
## Different iterative procedures
###################################################

"""
    `IterativeState`
    Abstract type, represents all information of a state of path/timingscomputation
    in the iterative process
    Must contain:
    - `data::NetworkData`           timing data in the network
    - `timings::NetworkTimings`     the current timings solution
    - `trips::Vector{NetworkTrip}`  trips that we currently optimize on
    - `paths::Vector{Vector{Dict{Edge, Float64}}}` path subset for each current trip datapoint. Each trip has a vector of paths associated to it. Each path is represented as a dictionary mapping edges to weights. This ensures that the path representation is consistent for all types of methods (including graph reduction). In most cases, the weights are all ones and the representation is equivalent to a vector of edges.
    - `pathDiff::Float64`           measure of difference in paths from previous step. Full definition is in paper. The lower it is, the closer we are to convergence.
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
        updateState!(it, lpTimes(it; solverArgs...))
    elseif method=="fraclp"
        updateState!(it, fraclpTimes(it; solverArgs...))
    elseif method=="mip"
        updateState!(it, mipTimes(it; solverArgs...))
    elseif method == "heuristic"
        updateState!(it, heuristicTimes(it))
    elseif method == "socp"
        updateState!(it, socpTimes(it; solverArgs...))
    elseif method == "roadtype"
        updateState!(it, constantSpeedTimes(it; solverArgs...))
    elseif method == "constant"
        updateState!(it, constantSpeedTimes(it; uniqueSpeed=true, solverArgs...))
    elseif method == "lpCo"
        updateState!(it, lpTimes(it, continuityConstraint="simple",
                                     velocityBound=velocityBound; solverArgs...))
    elseif method == "lpCoNbhd"
        updateState!(it, lpTimes(it, continuityConstraint="neighborhoods",
                                     velocityBound=velocityBound; solverArgs...))
    elseif method == "socpCo"
        updateState!(it, socpTimes(it, continuityConstraint="simple",
                                       velocityBound=velocityBound; solverArgs...))
    elseif method == "socpCoNbhd"
        updateState!(it, socpTimes(it, continuityConstraint="neighborhoods",
                                       velocityBound=velocityBound; solverArgs...))
    else
        error("Unknown optimizer")
    end
    return it
end
