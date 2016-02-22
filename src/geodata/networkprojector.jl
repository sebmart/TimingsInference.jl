###################################################
## networkprojector.jl
## link geographical and network data
###################################################

"""
    `NetworkProjector`: abstract type that creates a link between NetworkData and GeoData
    is used to project geographical data onto network and to use network results
    must implement attributes:
    - `network::Network`
    - `trips::GeoData` : reference to trip data
    methods:
    - `preloadData!`: takes GeoData and load it
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
    trips::GeoData

    "projection KD-tree"
    tree::KDTree
    "precomputation (trip->node projections)"
    proj::Vector{Tuple{Int,Int}}

    function NearestNode(n::Network)
        obj = new()
        obj.network = n
        obj.trips = GeoData()
        obj.proj  = Tuple{Int,Int}[]
        # Constructing tree
        dataPos = Array(Float64,(2,length(n.nodes)))
        for (i,node) in enumerate(n.nodes)
           dataPos[1,i] = node.x
           dataPos[2,i] = node.y
        end
        obj.tree = KDTree(dataPos)
        return obj
    end
end

"""
    `NearestNode` extended constructor: also preloads the data
"""
function NearestNode(n::Network, trips::GeoData)
    nn = NearestNode(n)
    preloadData!(nn, trips)
    return nn
end

"""
    `preloadData!`: project all trips onto their nearest node
"""
function preloadData!(nn::NearestNode, trips::GeoData)
    nTrips = length(trips)
    println("Projecting $nTrips geo-trips onto network-nodes...")
    #initializing containers
    nn.trips = trips
    nn.proj = Array(Tuple{Int,Int},nTrips)
    for (i,t) in enumerate(trips)
        if i%100_000 == 0
            @printf("\r%.2f%% trips projected     ",100*i/nTrips)
        end
        pX, pY = toENU(t.pLon, t.pLat, nn.network)
        idP = knn(nn.tree,[pX,pY],1)[1][1]
        dX, dY = toENU(t.dLon, t.dLat, nn.network)
        idD = knn(nn.tree,[dX,dY],1)[1][1]
        nn.proj[i] = (idP,idD)
    end
    println("\r100.00% trips projected     ")
    return nn
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
            netTrips[od] = NetworkTrip(nt.orig, nt.dest, time, nt.weight+1.)
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
    return timings.pathTimes[o,d]
end
function getTripTiming(nn::NearestNode, timings::NetworkTimings, t::GeoTrip)
    pX, pY = toENU(t.pLon, t.pLat, nn.network)
    o = knn(nn.tree,[Float32(pX),Float32(pY)],1)[1][1]
    dX, dY = toENU(t.dLon, t.dLat, nn.network)
    d = knn(nn.tree,[Float32(dX),Float32(dY)],1)[1][1]
    return timings.pathTimes[o,d]
end

type AvgRadius <: NetworkProjector
    # compulsory attributes
    network::Network
    trips::GeoData

    "radius"
    radius::Float64
    "projection KD-tree (contains rides)"
    tree::KDTree
    "precomputation (node->trip list)"
    nodeList::Vector{Vector{Tuple{Int,Int}}}

    function AvgRadius(n::Network, r::Float64)
        obj = new()
        obj.radius = r
        obj.network = n
        obj.trips = GeoData[]
        obj.nodeList = Vector{Tuple{Int,Int}}[]
        nNodePairs = length(n.nodes) * length(n.nodes)
        println("Creating KDTree...")
        dataPos = Array(Float64,(4, nNodePairs))
        for (i, startNode) in enumerate(n.nodes), (j, endNode) in enumerate(n.nodes)
            dataPos[1, (i-1) * length(n.nodes) + j] = startNode.x
            dataPos[2, (i-1) * length(n.nodes) + j] = startNode.y
            dataPos[3, (i-1) * length(n.nodes) + j] = endNode.x
            dataPos[4, (i-1) * length(n.nodes) + j] = endNode.y
        end
        obj.tree = KDTree(dataPos)
        return obj
    end
end

"""
    `AvgRadius` extended constructor: also preloads the data
"""
function AvgRadius(n::Network, r::Float64, trips::GeoData)
    ar = AvgRadius(n, r)
    preloadData!(ar, trips)
    return ar
end
AvgRadius(n::Network, r::Int, trips::GeoData) = AvgRadius(n, Float64(r), trips)

"""
    `preloadData!`: project all trips onto their nearest node
"""
function preloadData!(ar::AvgRadius, trips::GeoData)
    nTrips = length(trips)
    println("Projecting $nTrips geo-trips onto network-nodes...")
    #initializing containers
    ar.trips = trips
    ar.nodeList = Array(Vector{Tuple{Int,Int}}, nTrips)

    # helper function to map from single index to node pair
    function decipherNodePairIndex(idx::Int)
        nNodes = length(ar.network.nodes)
        startNode = Int(div(idx - 1, nNodes)) + 1
        endNode = idx % nNodes
        if endNode == 0
            endNode = nNodes
        end
        return (startNode, endNode)
    end

    for (i,t) in enumerate(trips)
        if i%100_000 == 0
            @printf("\r%.2f%% trips projected     ",100*i/nTrips)
        end
        pX, pY = toENU(t.pLon, t.pLat, ar.network)
        dX, dY = toENU(t.dLon, t.dLat, ar.network)
        tripLocation = [pX, pY, dX, dY]
        nodes = inrange(ar.tree, tripLocation, ar.radius)
        tmpNodeList = map(decipherNodePairIndex, nodes)
        ar.nodeList[i] = tmpNodeList[map(isValidNodePair, tmpNodeList)]
        # if length(ar.nodeList[i]) == 0
        #     # do something if necessary
        # end
    end
    println("\r100.00% trips projected     ")
    return ar
end

"""
    `getNetworkTrips`: constructs list of NetworkTrip objects
"""
function getNetworkTrips(ar::AvgRadius, tIds::AbstractArray{Int64,1})
    if length(ar.trips) < length(tIds)
        error("Trips not loaded yet")
    end
    # Store result in dictionary : (orig,dest)->NetworkTrip
    netTrips = Dict{Tuple{Int,Int},NetworkTrip}()
    for id in tIds
        t = ar.trips[id]
        nodePairs = ar.nodeList[id]
        for od in nodePairs
            #if same origin/destination
            if od[1] == od[2]
                continue
            end
            if haskey(netTrips, od)
                nt = netTrips[od]
                time = nt.time * nt.weight/(nt.weight + 1.) + t.time/(nt.weight + 1.)
                netTrips[od] = NetworkTrip(nt.orig, nt.dest, time, nt.weight+1.)
            else
                netTrips[od] = NetworkTrip(od[1],od[2],t.time,1.)
            end
        end
    end
    return collect(values(netTrips))
end

"""
    `getTripTiming`: returns a trip timing estimation from a NetworkTimings result
"""
function getTripTiming(ar::AvgRadius, timings::NetworkTimings, tId::Int)
    nodePairs = ar.nodeList[tId]
    # average over neighboring nodes
    time = 0.
    for od in nodePairs
        time += timings.pathTimes[od[1], od[2]]
    end
    return time / length(nodePairs)
end
function getTripTiming(ar::AvgRadius, timings::NetworkTimings, t::GeoTrip)

    # helper function to go from single index in KDTree to pair of nodes
    function decipherNodePairIndex(idx::Int)
        nNodes = length(ar.network.nodes)
        startNode = Int(div(idx - 1, nNodes)) + 1
        endNode = idx % nNodes
        if endNode == 0
            endNode = nNodes
        end
        return (startNode, endNode)
    end

    # find nodes within radius
    pX, pY = toENU(t.pLon, t.pLat, ar.network)
    dX, dY = toENU(t.dLon, t.dLat, ar.network)
    tripLocation = [Float32(pX), Float32(pY), Float32(dX), Float32(dY)]
    nodePairs = inrange(ar.tree, tripLocation, ar.radius)
    nodePairs = map(decipherNodePairIndex, nodePairs)
    nodePairs = tmpNodes[map(isValidNodePair, nodePairs)]
    # average travel times
    time = 0.
    for od in nodePairs
        time += timings.pathTimes[od[1], od[2]]
    end
    return time / length(nodePairs)
end

"""
    `isValidNodePair`: helper function to check different start and end
"""
isValidNodePair(nodePair::Tuple{Int,Int}) = (nodePair[1] != nodePair[2])
