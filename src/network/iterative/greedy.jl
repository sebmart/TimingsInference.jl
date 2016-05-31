###################################################
## network/iterative/greedy.jl
## Iterative state with fixed subse
###################################################

"""
    `GreedyEdges`, Iterative state optimizing on static trip list (subset of data)
    - each trip has a fixed max number of paths
    - Default number of paths per trip is infinite
    - Set of independent edges is updated at every iteration
"""
type GreedyEdges <: IterativeState
    # inherited attributes
    data::NetworkData
    timings::NetworkTimings
    trips::Vector{NetworkTrip}
    paths::Vector{Vector{Dict{Edge,Float64}}}  # for each trip, a vector of paths
    fixedTime::Float64

    "max number of paths per trip"
    pathsPerTrip::Int64
    "independent edges"
    independent::Vector{Edge}
    "dependent edges"
    dependent::Vector{Edge}
    "original non-simplified paths"
    origPaths::Vector{Vector{Vector{Edge}}}
    "dependency matrix"
    dependencies::SparseMatrixCSC{Float64,Int}
    "edge map"
    edgeMap::Dict{Edge,Int}
    "number of edges to remove"
    numEdges::Int
end

"""
    Creates initial fixed number of paths per trip state
    takes in NetworkData object, initial timings (as link times or full timings),
    and max number of paths per trip as integer
"""
function GreedyEdges(data::NetworkData, startSolution::NetworkTimings; pathsPerTrip::Int = typemax(Int), maxTrip::Int=1000, numEdges::Int = 10)
    if pathsPerTrip < 1
        error("Must have at least one path per trip")
    end
    # randomly select the trips
    srand(1991)
    trips = shuffle(data.trips)[1:min(maxTrip,length(data.trips))]
    # One path per trip: the initial shortest path
    paths = [Dict{Edge,Float64}[[edge => 1. for edge in getPathEdges(startSolution, t.orig, t.dest)]] for t in trips]
    origPaths = [Vector{Edge}[getPathEdges(startSolution, t.orig, t.dest)] for t in trips]
    independent = collect(edges(data.network.graph))
    dependent = Edge[]
    dependencies, edgeMap = findNetworkDependence(data.network, independent, dependent, numDeps = 3)
    return GreedyEdges(data,startSolution,trips,paths,0.,pathsPerTrip,independent, dependent,origPaths,dependencies,edgeMap,numEdges)
end

GreedyEdges(data::NetworkData, initTimes::AbstractArray{Float64, 2}; args...) =
    GreedyEdges(data, NetworkTimings(data.network, initTimes); args...)

"""
    Update paths of GreedyEdges object given new times
"""
function updateState!(s::GreedyEdges, times::AbstractArray{Float64, 2}, fixedTime = 0.)
    s.fixedTime = fixedTime
    # update the timings and compute shortest paths
    newTimes = evaluateTimes(s.data.network, s.dependencies, times, s.independent, s.edgeMap)
    s.timings = NetworkTimings(s.data.network, newTimes)
    # update independent set and dependencies
    s.independent, s.dependent = updateIndependentEdges(s.paths, s.independent, s.dependent, s.numEdges)
    s.dependencies, s.edgeMap = findNetworkDependence(s.data.network, s.independent, s.dependent, numDeps = 3)
    # update paths 
    for (d,t) in enumerate(s.trips)
        sp = getPathEdges(s.timings, t.orig, t.dest)
        if s.pathsPerTrip == 1
            s.origPaths[d][1] = sp
        else
            index = findfirst(s.origPaths[d], sp)
            if index != 0   # if so, put it in first position
                s.origPaths[d][index], s.origPaths[d][1] = s.origPaths[d][1], s.origPaths[d][index] #swap
            elseif length(s.origPaths[d]) < s.pathsPerTrip # if not, and if enough room to add, add it in first position
                unshift!(s.origPaths[d], sp)
            else        # replace least useful path
                worstIndex = indmax([pathEdgesTime(s.timings, p) for p in s.origPaths[d]])
                s.origPaths[d][worstIndex] = s.origPaths[d][1]
                s.origPaths[d][1] = sp
            end
        end
    end
    s.paths = [[simplifyPath(p, s.independent, s.dependencies, s.edgeMap) for p in s.origPaths[d]] for d = eachindex(s.trips)]
end