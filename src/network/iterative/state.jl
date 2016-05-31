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
    - `fixedTime::Float64` extra fixed time for all rides, in seconds
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
fixedTime(it::IterativeState) = it.fixedTime

"""
    `doIteration!`, shortcut to update state with optimizer's output
"""
function doIteration!(it::IterativeState; method::AbstractString="lp", ft::Bool = false, solverArgs...)
    if method=="lp"
        times, fixedTime = lpTimes(it, ft, solverArgs...)
        updateState!(it, times, fixedTime)
    elseif method=="fraclp"
        times, fixedTime = fraclpTimes(it, ft, solverArgs...)
        updateState!(it, times, fixedTime)
    elseif method=="mip"
        updateState!(it, mipTimes(it, solverArgs...))
    elseif method == "heuristic"
        updateState!(it, heuristicTimes(it))
    elseif method == "redlp"
        updateState!(it, redlpTimes(it, solverArgs...))
    elseif method == "socp"
        times, fixedTime = socpTimes(it, ft, solverArgs...)
        updateState!(it, times, fixedTime)
    else
        error("Unknown optimizer")
    end
    return it
end
