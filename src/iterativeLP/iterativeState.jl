###################################################
## iterativeState.jl
## Different iterative procedures
###################################################

"""
    `IterativeState`
    Abstract type, represents all information of a state of path/timings computation
    in the iterative process
    Must contain:
    - `data::NetworkData`          timing data in the network
    - `timings::NetworkTimings`    the current timings solution
    - `trips::Vector{NetworkTrip}` trips that we currently optimize on
    - `paths::Vector{Vector{Int}}` path subset for each current trip datapoint
    Must implement:
    - `updateState!` updates the state when new timings are computed
    - a constructor that initialize the instance with using a NetworkData object

"""
abstract IterativeState


function Base.show(io::IO, s::IterativeState)
    nTrips = length(s.trips)
    nPaths = sum([length(paths) for paths in s.paths])
    println(io,"Iterative heuristic: $(string(typeof(s)))")
    println(io,"Optimizing on $nTrips trips and $nPaths paths")
end

"""
    `StaticState`
     Iterative state optimizing on static data
     - do not add or remove datapoints, use them all
     - for now, no path limitation
"""
type StaticIterative <: IterativeState
    # inherited attributes
    data::NetworkData
    timings::NetworkTimings
    trips::Vector{NetworkTrip}
    paths::Vector{Vector{Vector{Int}}} # for each trip, a vector of paths
end

"""
    initialize from NetworkData
    - for now, randomly subsets the data to fit trip_number
"""
function StaticIterative(data::NetworkData, initTimes::AbstractArray{Float64,2};
    max_trip::Int=1000)
    timings = NetworkTimings(data.network, initTimes)

    # randomly select the trips
    srand(1991)
    trips = shuffle(data.trips)[1:min(max_trip,length(data.trips))]
    # One path per trip: the initial shortest path
    paths = [Vector{Int}[getPath(timings, t.orig, t.dest)] for t in trips]
    return StaticIterative(data,timings,trips,paths)
end

"""
    update paths of StaticState object given new timings
"""
function updateState!(s::StaticIterative, times::AbstractArray{Float64,2})

    #update the timings and compute shortest paths
    s.timings = NetworkTimings(s.data.network, times)

    #for all data point, check if we already have the new path.
    for (d,t) in enumerate(s.trips)
        sp = getPath(s.timings, t.orig, t.dest)
        index = findfirst(s.paths[d],sp)
        if index == 0     # if so, put it in first position
            unshift!(s.paths[d], sp)
        else    # if not, add it in first position
            s.paths[d][index], s.paths[d][1] = s.paths[d][1], s.paths[d][index] #swap
        end
    end

end
