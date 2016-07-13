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
    paths::Vector{Vector{Dict{Edge, Float64}}}  # for each trip, a vector of paths

    "max number of paths per trip"
    pathsPerTrip::Int64
    "only trips longer than tripLength get extra paths"
    tripLength::Float64
    "distances of network, used to estimate trip length"
    roadDistances::NetworkTimings
end

"""
    Creates initial fixed number of paths per trip state
    takes in NetworkData object, initial timings (as link times or full timings),
    and max number of paths per trip as integer
"""
function LimitedPaths(data::NetworkData, startSolution::NetworkTimings; pathsPerTrip::Int = typemax(Int), tripLength::Float64 = 0., maxTrip::Int=1000)
    if pathsPerTrip < 1
        error("Must have at least one path per trip")
    end
    # randomly select the trips
    srand(1991)
    trips = shuffle(data.trips)[1:min(maxTrip,length(data.trips))]
    # One path per trip: the initial shortest path
    paths = [Dict{Edge,Float64}[getFullPathEdges(t, startSolution)] for t in trips]
    roadDistances = NetworkTimings(data.network)
    return LimitedPaths(data,startSolution,trips,paths,pathsPerTrip,tripLength,roadDistances)
end

LimitedPaths(data::NetworkData, initTimes::AbstractArray{Float64, 2}; args...) =
    LimitedPaths(data, NetworkTimings(data.network, initTimes); args...)

heuristicPaths(data::NetworkData; maxTrip::Int=1000) = LimitedPaths(data, uniformTimes(data.network, 15.0), pathsPerTrip=1, maxTrip=maxTrip)

"""
    Update paths of LimitedPaths object given new times
"""
function updateState!(s::LimitedPaths, times::AbstractArray{Float64, 2})
    # update the timings and compute shortest paths
    s.timings = NetworkTimings(s.data.network, times)

    for (d,t) in enumerate(s.trips)
        # get new shortest path with extra edges if necessary
        sp = getFullPathEdges(t, s.timings)
        if s.pathsPerTrip == 1 || traveltime(s.roadDistances, t.orig, t.dest) < s.tripLength # short trips get one path
            s.paths[d][1] = sp
        else
            index = findfirst(s.paths[d],sp)
            if index != 0   # if so, put it in first position
                s.paths[d][index], s.paths[d][1] = s.paths[d][1], s.paths[d][index] #swap
            elseif length(s.paths[d]) < s.pathsPerTrip # if not, and if enough room to add, add it in first position
                unshift!(s.paths[d], sp)
            else        # replace least useful path
                worstIndex = indmax([pathEdgesTime(s.timings, collect(keys(p))) for p in s.paths[d]])
                s.paths[d][worstIndex] = s.paths[d][1]
                s.paths[d][1] = sp
            end
        end
    end
end
