###################################################
## network/iterative/limitedpaths.jl
## Iterative state with fixed subse
###################################################

"""
    `LimitedPaths`, Iterative state optimizing on static trip list (subset of data)
    - each trip has a fixed max number of paths
    - Default number of paths per trip is infinite
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
    paths = [Vector{Int}[getPath(startSolution, t.orig, t.dest)] for t in trips]
    return LimitedPaths(data,startSolution,trips,paths,pathsPerTrip)
end

LimitedPaths(data::NetworkData, initTimes::AbstractArray{Float64, 2}; args...) =
    LimitedPaths(data, NetworkTimings(data.network, initTimes); args...)


"""
    Update paths of LimitedPaths object given new times
"""
function updateState!(s::LimitedPaths, times::AbstractArray{Float64, 2})
    # update the timings and compute shortest paths
    s.timings = NetworkTimings(s.data.network, times)

    if s.pathsPerTrip == 1
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