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
    rms1 = tripsRMS(s.timings,s.trips)
    rms2 = tripsRMS(s.timings,s.data.trips)

    println("Iterative heuristic: $(typeName) method")
    println("Optimizing on $(nTrips)/$(length(s.data.trips)) trips and $nPaths paths")
    println("\n=================MAE====================")
    @printf("current trips: %.2f%%, all trips: %.2f%%\n",  100*mae1, 100*mae2)
    println("\n=================RMS====================")
    @printf("current trips: %.2f%%, all trips: %.2f%%\n",  100*rms1, 100*rms2)
    return
end

function printStats(s::IterativeState, ref::NetworkTimings)
    printStats(s)
    mae1 = allPathsMAE(ref,s.timings)
    mae2 = roadTimeMAE(ref,s.timings)
    rms1 = allPathsRMS(ref,s.timings)
    rms2 = roadTimeRMS(ref,s.timings)
    mae3 = tripsMAE(ref,s.trips)
    mae4 = tripsMAE(ref,s.data.trips)
    rms3 = tripsRMS(ref,s.trips)
    rms4 = tripsRMS(ref,s.data.trips)

    println("\n========From reference timings==========")
    @printf("All paths: MAE=%.2f%%, RMS=%.2f%%\n",  100*mae1, 100*rms1)
    @printf("All roads: MAE=%.2f%%, RMS=%.2f%%\n",  100*mae2, 100*rms2)
    println("\n==============Data Noise================")
    @printf("current trips: MAE=%.2f%%, RMS=%.2f%%\n",  100*mae3, 100*rms3)
    @printf("    all trips: MAE=%.2f%%, RMS=%.2f%%\n",  100*mae4, 100*rms4)
    return
end

"""
    `FixedNumPathsPerTripState`
    Iterative state optimizing on static trip list, with each trip having a fixed max number of paths
    Paths are removed on a per-trip basis
    Default number of paths per trip is infinite
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
function FixedNumPathsPerTripState(data::NetworkData, initTimes::AbstractArray{Float64, 2}; maxNumPathsPerTrip::Int = typemax(Int), maxTrip::Int=1000)
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
            elseif length(s.paths[d]) < s.maxNumPathsPerTrip # if not, and if enough room to add, add it in first position
                unshift!(s.paths[d], sp)
            else        # replace least useful path
                worstIndex = indmax([pathTime(s.timings, p) for p in s.paths[d]])
                s.paths[d][worstIndex] = s.paths[d][1]
                s.paths[d][1] = sp
            end
        end
    end
end
