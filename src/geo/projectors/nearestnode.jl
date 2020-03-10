###################################################
## geo/projectors/nearestnode.jl
## implementation of network projector with nn projection
###################################################

"""
    `NearestNode` : Projects trips to the nearest nodes, give the associated prediction
"""
mutable struct NearestNode <: NetworkProjector
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
        dataPos = Array{Float64}(undef, (2,length(n.nodes)))
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
    nn.proj = Array{Tuple{Int,Int}}(undef, nTrips)
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
            time = nt.time ^ (nt.weight/(nt.weight + 1.)) * t.time^(1/(nt.weight + 1.))
            netTrips[od] = NetworkTrip(nt.orig, nt.dest, time, nt.weight+1., false)
        else
            netTrips[od] = NetworkTrip((od[1], od[1], 0.), (od[2], od[2], 0.), t.time, 1., false)
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
function getTripTiming(nn::NearestNode, timings::NetworkTimings,
            pLon::Float32, pLat::Float32, dLon::Float32, dLat::Float32)
    pX, pY = toENU(pLon, pLat, nn.network)
    o = knn(nn.tree,[pX,pY],1)[1][1]
    dX, dY = toENU(dLon, dLat, nn.network)
    d = knn(nn.tree,[dX,dY],1)[1][1]
    return timings.pathTimes[o,d]
end
