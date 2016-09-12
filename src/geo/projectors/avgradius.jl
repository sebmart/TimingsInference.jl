###################################################
## projectors/avgradius.jl
## implementation of network projector with radius projection
###################################################

"""
    `AvgRadius` : Projects trips to nodes within given radius, give the associated prediction
    If no available nodes within radius, projects to (at most) 3 nearest neighbors
"""
type AvgRadius <: NetworkProjector
    # compulsory attributes
    network::Network
    trips::GeoData

    "radius, in meters"
    radius::Float64
    "projection KD-tree (contains rides)"
    tree::KDTree
    "precomputation (node->trip list)"
    nodeList::Vector{Vector{Tuple{Int,Int}}}

    function AvgRadius(n::Network, r::Real)
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
function AvgRadius(n::Network, r::Real, trips::GeoData)
    ar = AvgRadius(n, r)
    preloadData!(ar, trips)
    return ar
end

"""
    `preloadData!`: project all trips onto the node pairs within the given radius
"""
function preloadData!(ar::AvgRadius, trips::GeoData)
    nTrips = length(trips)
    println("Projecting $nTrips geo-trips onto network-nodes...")
    #initializing containers
    ar.trips = trips
    ar.nodeList = Array(Vector{Tuple{Int,Int}}, nTrips)

    for (i,t) in enumerate(trips)
        if i%100_000 == 0
            @printf("\r%.2f%% trips projected     ",100*i/nTrips)
        end
        pX, pY = toENU(t.pLon, t.pLat, ar.network)
        dX, dY = toENU(t.dLon, t.dLat, ar.network)
        tripLocation = [pX, pY, dX, dY]
        nodePairs = inrange(ar.tree, tripLocation, ar.radius)
        if length(nodePairs) == 0
            nodePairs, dists = knn(ar.tree, tripLocation, 3)
        end
        nodePairs = [decipherNodePairIndex(node, length(ar.network.nodes)) for node in nodePairs]
        ar.nodeList[i] = nodePairs[map(isValidNodePair, nodePairs)]
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
        # compute weight of trip = inverse of number of ODs (network trips) it will be added to
        tripWeight = 1/length(nodePairs)
        for od in nodePairs
            #if same origin/destination
            if od[1] == od[2]
                continue
            end
            # check if network trip for this OD pair already exists
            if haskey(netTrips, od)
                nt = netTrips[od]
                # compute new time = weighted average of times
                time = (nt.time * nt.weight + t.time * tripWeight)/(nt.weight + tripWeight)
                # update time and wait
                netTrips[od] = NetworkTrip(nt.orig, nt.dest, time, nt.weight + tripWeight, false)
            else
                # create new network trip
                netTrips[od] = NetworkTrip((od[1], od[1], 0.), (od[2], od[2], 0.), t.time, tripWeight, false)
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
function getTripTiming(ar::AvgRadius, timings::NetworkTimings,
        pLon::Float32, pLat::Float32, dLon::Float32, dLat::Float32)
    # find nodes within radius
    pX, pY = toENU(pLon, pLat, ar.network)
    dX, dY = toENU(dLon, dLat, ar.network)
    tripLocation = [pX, pY, dX, dY]
    nodePairs = inrange(ar.tree, tripLocation, ar.radius)
    nodePairs = [decipherNodePairIndex(node, length(ar.network.nodes)) for node in nodePairs]
    nodePairs = nodePairs[map(isValidNodePair, nodePairs)]
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

"""
    `decipherNodePairIndex`: helper function to go from single index in KDTree to node pair
"""
function decipherNodePairIndex(idx::Int, nNodes::Int)
    startNode = Int(div(idx - 1, nNodes)) + 1
    endNode = idx % nNodes
    if endNode == 0
        endNode = nNodes
    end
    return (startNode, endNode)
end
