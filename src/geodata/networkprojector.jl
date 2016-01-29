###################################################
## networkprojector.jl
## link geographical and network data
###################################################

"""
    `NetworkProjector`: abstract type that the link between NetworkData and GeoData
    is used to project geographical data onto network and to use network results
    must implements attributes:
    - `network::Network`
    - `trips::TripData` : reference to trip data
    methods:
    - `preloadData!`: takes TripData and load it
    - `getNetworkTrips`: returns network trips associated with given geo-trips
    - `getTripTiming` : returns timing estimation for a geographical trip (random or known)
"""
abstract NetworkProjector

function Base.show(io::IO, p::NetworkProjector)
    typeName = split(string(typeof(p)),".")[end]
    nTrips = length(p.trips)
    println(io,"Network Projector: $(typeName)")
    println(io,"$nTrips trips pre-loaded")
end


"""
    `NetworkData` : convenience function to create NetworkData using Projector
"""
function NetworkData(
        proj::NetworkProjector,
        trips::AbstractArray{Int64,1} = eachindex(proj.trips),
        minTimes::AbstractArray{Float64,2} = maxSpeedTimes(proj.network); #max speeds timings
        args...)
    # Create the "NetworkTrip" array
    return NetworkData(proj.network, getNetworkTrips(proj, trips, args...), minTimes)
end


"""
    `NearestNode` : Projects trips to the nearest nodes, give the associated prediction
"""
type NearestNode <: NetworkProjector
    # compulsory attributes
    network::Network
    trips::TripData

    # projection KD-tree
    tree::KDTree
    # precomputation (trip->node projections)
    proj::Vector{Tuple{Int,Int}}

    function NearestNode(n::Network)
        obj = new()
        obj.network = n
        obj.trips = TripData[]
        obj.proj  = Tuple{Int,Int}[]
        # Constructing tree
        dataPos = Array(Float32,(2,length(n.nodes)))
        for (i,node) in enumerate(n.nodes)
           dataPos[1,i] = node.lon
           dataPos[2,i] = node.lat
        end
        obj.tree = KDTree(dataPos)
        obj
    end
end

"""
    `NearestNode` extended constructor: also preloads the data
"""
function NearestNode(n::Network, trips::TripData)
    nn = NearestNode(n)
    preloadData!(nn, trips)
    nn
end

"""
    `preloadData!`: project all trips onto their nearest node
"""
function preloadData!(nn::NearestNode, trips::TripData)
    nTrips = length(trips)
    println("Projecting $nTrips geo-trips onto network-nodes...")
    #initializing containers
    nn.trips = trips
    nn.proj = Array(Tuple{Int,Int},nTrips)
    for (i,t) in enumerate(trips)
        if i%100_000 == 0
            @printf("\r%.2f%% trips projected     ",100*i/nTrips)
        end
        idP = knn(nn.tree,[t.pLon,t.pLat],1)[1][1]
        idD = knn(nn.tree,[t.dLon,t.dLat],1)[1][1]
        nn.proj[i] = (idP,idD)
    end
    println("\r100.00% trips projected     ")
    nn
end

"""
    `getNetworkTrips`: constructs list of NetworkTrip objects
"""
function getNetworkTrips(nn::NearestNode, tIds::AbstractArray{Int64,1})
    if length(nn.trips) < length(tIds)
        error("Trips not loaded yet")
    end
    #Store result in dictionary : (orig,dest)->NetworkTrip
    netTrips = Dict{Tuple{Int,Int},NetworkTrip}()
    for id in tIds
        t = nn.trips[id]
        od = nn.proj[id]
        #if same origin/destination
        if od[1] == od[2]
            continue
        end
        if haskey(netTrips, od)
            nt = netTrips[od]
            time = nt.time * nt.weight/(nt.weight + 1.) + t.time/(nt.weight + 1.)
            netTrips[od] = NetworkTrip(nt.orig,nt.dest,time, nt.weight+1.)
        else
            netTrips[od] = NetworkTrip(od[1],od[2],t.time,1.)
        end
    end
    return collect(values(netTrips))
end

"""
    `getTripTiming`: returns a trip timing estimation from a NetworkTimings result
"""
function getTripTiming(nn::NearestNode, timings::NetworkTimings, tId::Int)
    o,d = nn.proj[tId]
    return timings.pathTime[o,d]
end
function getTripTiming(nn::NearestNode, timings::NetworkTimings, t::GeoTrip)
    o = knn(nn.tree,[t.pLon,t.pLat],1)[1][1]
    d = knn(nn.tree,[t.dLon,t.dLat],1)[1][1]
    return timings.pathTime[o,d]
end
