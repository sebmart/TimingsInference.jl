###################################################
## projectors/nearestroad.jl
## implementation of NetworkProjector with nearest road projection
###################################################

"""
	`NearestRoad` : projects ride origin and destination to nearest road
"""
type NearestRoad <: NetworkProjector
	# compulsory attributes
    network::Network
    trips::GeoData

    "projection KD-tree"
    tree::KDTree
    "precomputation (trip->road projections)"
    proj::Vector{Tuple{Edge,Float64,Edge,Float64}}

    function NearestRoad(n::Network)
        obj = new()
        obj.network = n
        obj.trips = GeoData()
        obj.proj  = Tuple{Edge,Float64,Edge,Float64}[]
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
    `NearestRoad` extended constructor: also preloads the data
"""
function NearestRoad(n::Network, trips::GeoData)
    nr = NearestRoad(n)
    preloadData!(nr, trips)
    return nr
end

"""
    `preloadData!`: project all trips onto their nearest road (start and end)
"""
function preloadData!(nr::NearestRoad, trips::GeoData)
    nTrips = length(trips)
    println("Projecting $nTrips geo-trips onto network roads...")
    #initializing containers
    nr.trips = trips
    nr.proj = Array(Tuple{Edge,Float64,Edge,Float64},nTrips)
    for (i,t) in enumerate(trips)
        if i % 50_000 == 0
            @printf("\r%.2f%% trips projected     ",100*i/nTrips)
        end
        pX, pY = toENU(t.pLon, t.pLat, nr.network)
        pEdge, pWeight = toClosestEdge(nr, pX, pY)
        dX, dY = toENU(t.dLon, t.dLat, nr.network)
        dEdge, dWeight = toClosestEdge(nr, dX, dY)
        nr.proj[i] = (pEdge, pWeight, dEdge, dWeight)
    end
    println("\r100.00% trips projected     ")
    return nr
end

"""
	`projectDist`	:	find distance of edge to point
"""
function projectDist(n::Network, edge::Edge, x::Float64, y::Float64)
	# define points 
	orig = [n.nodes[src(edge)].x, n.nodes[src(edge)].y]
	dest = [n.nodes[dst(edge)].x, n.nodes[dst(edge)].y]
	point = [x, y]
	# compute projection (t is parameter of line defined by vector dest - orig)
	# t must be fixed between 0 and 1 to project onto a line segment
	t = min(1, max(0, dot(point - orig, dest - orig)/norm(dest-orig)^2))
	projection = orig + t * (dest - orig)
	return norm(projection - point), t
end

"""
	`toClosestEdge`	: find closest edge from point and proportion of edge to be added to path
"""
function toClosestEdge(nr::NearestRoad, x::Float64, y::Float64)
	# find relevant edges
	nearNodes = inrange(nr.tree, [x,y], 500.)
	edges = findEdges(nr.network, nearNodes)
	# look for minimum distance edge
	minDist = 500.
	projEdge = Edge(0,0)
	projWeight = 0.
	for edge in edges
		dist, t = projectDist(nr.network, edge, x, y)
		if dist < minDist
			minDist = dist
			projEdge = edge
			projWeight = 1 - t
		end
	end
	# if this is a two-way street, check which side of the road it should be mapped to
	if Edge(dst(projEdge), src(projEdge)) in edges
		o = [nr.network.nodes[src(projEdge)].x, nr.network.nodes[src(projEdge)].y, 0.]
		d = [nr.network.nodes[dst(projEdge)].x, nr.network.nodes[dst(projEdge)].y, 0.]
		p = [x, y, 0.]
		if cross(p-o, p-d)[3] > 0
			projEdge = Edge(dst(projEdge), src(projEdge))
			projWeight = 1 - projWeight
		end
	end
	return projEdge, projWeight
end

"""
    `getNetworkTrips`: constructs list of NetworkTrip objects
"""
function getNetworkTrips(nr::NearestRoad, tIds::AbstractArray{Int64,1})
    if length(nr.trips) < length(tIds)
        error("Trips not loaded yet")
    end
    #Store result in array
    netTrips = Array(NetworkTrip, length(tIds))
    for (i,id) in enumerate(tIds)
        t = nr.trips[id]
        (pEdge, pWeight, dEdge, dWeight) = nr.proj[id]
        #if same origin/destination
        if pEdge == dEdge
            continue
        end
        netTrips[i] = NetworkTrip((src(pEdge), dst(pEdge), pWeight), (src(dEdge), dst(dEdge), dWeight), t.time, 1., true)
    end
    return netTrips
end

"""
    `getTripTiming`: returns a trip timing estimation from a NetworkTimings result
"""
function getTripTiming(nr::NearestRoad, timings::NetworkTimings, tId::Int)
    pEdge, pWeight, dEdge, dWeight = nr.proj[tId]
    return pWeight * timings.times[src(pEdge), dst(pEdge)] + timings.pathTimes[dst(pEdge), src(dEdge)] + dWeight * timings.times[src(dEdge), dst(dEdge)]
end
function getTripTiming(nr::NearestRoad, timings::NetworkTimings,
            pLon::Float32, pLat::Float32, dLon::Float32, dLat::Float32)
    pX, pY = toENU(pLon, pLat, nn.network)
    pEdge, pWeight = toClosestEdge(nr, pX, pY)
    dX, dY = toENU(dLon, dLat, nn.network)
    dEdge, dWeight = toClosestEdge(nr, dX, dY)
    return pWeight * timings.times[src(pEdge), dst(pEdge)] + timings.pathTimes[dst(pEdge), src(dEdge)] + dWeight * timings.times[src(dEdge), dst(dEdge)]
end
