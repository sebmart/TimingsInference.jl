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
    - `paths::Vector{Vector{Vector{Int}}}` path subset for each current trip datapoint
    Must implement:
    - `updateState!` updates the state when new timings are computed
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

"""
    `printStats`: print statistics about the current iterative state
    - if `ref::NetworkTimings` optional argument represents "real" timings expectations
"""
function printStats(s::IterativeState)
    nTrips = length(s.trips)
    nPaths = sum([length(paths) for paths in s.paths])
    typeName = split(string(typeof(s)),".")[end]
    mae1 = tripsMAE(s.timings,s.trips)
    mae2 = tripsMAE(s.timings,s.data.trips)
    std1 = tripsStd(s.timings,s.trips)
    std2 = tripsStd(s.timings,s.data.trips)

    println("Iterative heuristic: $(typeName) method")
    println("Optimizing on $(nTrips)/$(length(s.data.trips)) trips and $nPaths paths")
    println("\n=================MAE====================")
    @printf("current trips: %.2f%%, all trips: %.2f%%\n",  100*mae1, 100*mae2)
    println("\n==============Error std=================")
    @printf("current trips: %.2f%%, all trips: %.2f%%\n",  100*std1, 100*std2)
    return
end

function printStats(s::IterativeState, ref::NetworkTimings)
    printStats(s)
    mae1 = allPathsMAE(ref,s.timings)
    mae2 = roadTimeMAE(ref,s.timings)
    std1 = allPathsStd(ref,s.timings)
    std2 = roadTimeStd(ref,s.timings)
    mae3 = tripsMAE(ref,s.trips)
    mae4 = tripsMAE(ref,s.data.trips)
    std3 = tripsStd(ref,s.trips)
    std4 = tripsStd(ref,s.data.trips)

    println("\n========From reference timings==========")
    @printf("All paths: MAE=%.2f%%, STD=%.2f%%\n",  100*mae1, 100*std1)
    @printf("All roads: MAE=%.2f%%, STD=%.2f%%\n",  100*mae2, 100*std2)
    println("\n==============Data Noise================")
    @printf("current trips: MAE=%.2f%%, STD=%.2f%%\n",  100*mae3, 100*std3)
    @printf("    all trips: MAE=%.2f%%, STD=%.2f%%\n",  100*mae4, 100*std4)
    return
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
    maxTrip::Int=1000)
    timings = NetworkTimings(data.network, initTimes)

    # randomly select the trips
    srand(1991)
    trips = shuffle(data.trips)[1:min(maxTrip,length(data.trips))]
    # One path per trip: the initial shortest path
    paths = [Vector{Int}[getPath(timings, t.orig, t.dest)] for t in trips]
    return StaticIterative(data,timings,trips,paths)
end

"""
    update paths of StaticState object given new timings
"""
function updateState!(s::StaticIterative, times::AbstractArray{Float64,2})

    # update the timings and compute shortest paths
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

"""
    `FixedNumPathsPerTripState`
    Iterative state optimizing on static trip list, with each trip having a fixed max number of paths
    Paths are removed on a per-trip basis
"""
type FixedNumPathsPerTripState <: IterativeState
    # inherited attributes
    data::NetworkData
    timings::NetworkTimings
    trips::Vector{NetworkTrip}
    paths::Vector{Vector{Vector{Int}}}  # for each trip, a vector of paths
    maxNumPathsPerTrip::Int64           # maxNumber of paths per trip
end

"""
    Creates initial fixed number of paths per trip state
    takes in NetworkData object, initial times as 2D array, and max number of paths per trip as integer
"""
function FixedNumPathsPerTripState(data::NetworkData, initTimes::AbstractArray{Float64, 2}, maxNumPathsPerTrip::Int = 5; maxTrip::Int=1000)
    # check that enough paths per trip
    if maxNumPathsPerTrip < 1
        error("Must have at least one path per trip")
    end
    timings = NetworkTimings(data.network, initTimes)

    # randomly select the trips
    srand(1991)
    trips = shuffle(data.trips)[1:min(maxTrip,length(data.trips))]
    # One path per trip: the initial shortest path
    paths = [Vector{Int}[getPath(timings, t.orig, t.dest)] for t in trips]
    return FixedNumPathsPerTripState(data,timings,trips,paths,maxNumPathsPerTrip)
end

"""
    Update paths of FixedNumPathsPerTripState object given new times
"""
function updateState!(s::FixedNumPathsPerTripState, times::AbstractArray{Float64, 2})
    # update the timings and compute shortest paths
    s.timings = NetworkTimings(s.data.network, times)

    # for all data points, check if we already have the new path.
    for (d,t) in enumerate(s.trips)
        sp = getPath(s.timings, t.orig, t.dest)
        index = findfirst(s.paths[d],sp)
        if index != 0   # if so, put it in first position
            s.paths[d][index], s.paths[d][1] = s.paths[d][1], s.paths[d][index] #swap
        elseif length(s.paths[d]) < s.maxNumPathsPerTrip # if not, and if enough room to add, add it in first position
            unshift!(s.paths[d], sp)
        else        # replace least useful path
            worstIndex = findWorstPathIndex(s.paths[d], s.timings)
            s.paths[d][1], s.paths[d][worstIndex] = sp, s.paths[d][1] # swap and update
        end
    end
end

"""
    Find path that is least useful for a given trip (i.e. longest path)
"""
function findWorstPathIndex(paths::Vector{Vector{Int}}, t::NetworkTimings)
    pathTime = zeros(length(paths))
    for i = 1:length(pathTime)
        pathTime[i] = sum([t.times[paths[i][a],paths[i][a+1]] for a = 1:(length(paths[i])-1)])
    end
    return indmax(pathTime)
end