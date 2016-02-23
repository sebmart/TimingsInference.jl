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
    `LimitedPaths`
    Iterative state optimizing on static trip list,
    with each trip having a fixed max number of paths
    Paths are removed on a per-trip basis
    Default number of paths per trip is infinite
"""
type LimitedPaths <: IterativeState
    # inherited attributes
    data::NetworkData
    timings::NetworkTimings
    trips::Vector{NetworkTrip}
    paths::Vector{Vector{Vector{Int}}}  # for each trip, a vector of paths

    pathsPerTrip::Int64           # maxNumber of paths per trip
end

"""
    Creates initial fixed number of paths per trip state
    takes in NetworkData object, initial timings (as link times or full timings),
    and max number of paths per trip as integer
"""
function LimitedPaths(data::NetworkData, startSolution::NetworkTimings; pathsPerTrip::Int = typemax(Int), maxTrip::Int=1000)
    if pathsPerTrip < 1
        error("Must have at least one path per trip")
    end
    # randomly select the trips
    srand(1991)
    trips = shuffle(data.trips)[1:min(maxTrip,length(data.trips))]
    # One path per trip: the initial shortest path
    paths = [Vector{Int}[getPath(timings, t.orig, t.dest)] for t in trips]
    return LimitedPaths(data,timings,trips,paths,pathsPerTrip)
end

LimitedPaths(data::NetworkData, initTimes::AbstractArray{Float64, 2}; args...) =
    LimitedPaths(data, NetworkTimings(data.network, initTimes), args...)


"""
    Update paths of LimitedPaths object given new times
"""
function updateState!(s::LimitedPaths, times::AbstractArray{Float64, 2})
    # update the timings and compute shortest paths
    s.timings = NetworkTimings(s.data.network, times)

    if s.maxNumPathsPerTrip == 1
        for (d,t) in enumerate(s.trips)
            sp = getPath(s.timings, t.orig, t.dest)
            s.paths[d][1] = sp
        end
    else
        # for all data points, check if we already have the new path.
        for (d,t) in enumerate(s.trips)
            sp = getPath(s.timings, t.orig, t.dest)
            index = findfirst(s.paths[d],sp)
            if index != 0   # if so, put it in first position
                s.paths[d][index], s.paths[d][1] = s.paths[d][1], s.paths[d][index] #swap
            elseif length(s.paths[d]) < s.pathsPerTrip # if not, and if enough room to add, add it in first position
                unshift!(s.paths[d], sp)
            else        # replace least useful path
                worstIndex = indmax([pathTime(s.timings, p) for p in s.paths[d]])
                s.paths[d][worstIndex] = s.paths[d][1]
                s.paths[d][1] = sp
            end
        end
    end
end
