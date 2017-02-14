###################################################
## network/tools/edges.jl
## functions to study properties of edges/paths
###################################################

"""
	`findNearEdges` : find all edges that share a vertex with input e in network n, as a set of edges
"""
function findNearEdges(n::Network, e::Edge)
	orig = src(e)
	dest = dst(e)
	# find all edges that share a vertex with e
	nearEdges = [Edge(dest, newDest) for newDest in out_neighbors(n.graph, dest)]
	append!(nearEdges, [Edge(orig, newDest) for newDest in out_neighbors(n.graph, orig)])
	append!(nearEdges, [Edge(newOrig, orig) for newOrig in in_neighbors(n.graph, orig)])
	append!(nearEdges, [Edge(newOrig, dest) for newOrig in in_neighbors(n.graph, dest)])
	# remove duplicates and edge e itself
	nearEdges = Set(nearEdges)
	delete!(nearEdges, e)
	return nearEdges
end

"""
	`findNearEdgesSameType`	: find all edges that can be an out neighbor of input e in network n and are of the same type, as a set of edges
"""
function findNearEdgesSameType(n::Network, e::Edge)
	orig = src(e)
	dest = dst(e)
	# find all edges that share a vertex with e
	nearEdges = Set(out_edges(n.graph, dest))
	# remove duplicates and edge e itself (as well as the reverse of e)
	if reverse(e) in nearEdges
		delete!(nearEdges, reverse(e))
	end
	# remove edges not of same type as e
	for edge in nearEdges
		if n.roads[orig,dest].roadType != n.roads[src(edge),dst(edge)].roadType
			delete!(nearEdges, edge)
		end
	end
	return nearEdges
end

"""
	`clusterEdges` : group edges into rough clusters of neighbors
"""
function clusterEdges(n::Network, nNeighbors::Int=div(nRoads(n), 180))
	# define lists of edges and other inputs and outputs
	edgeList = collect(edges(n.graph))
	edgesAssigned = falses(length(edgeList))
	startingEdges = Set(Edge[])
	clusters = [Edge[] for i=1:nNeighbors]
	nodeMap = Dict{Int, Int}()
	# define starting points of clusters
	srand(2002)
	for i = 1:nNeighbors
		while true
			idx = rand(eachindex(edgeList))
			edge = edgeList[idx]
			if !(edge in startingEdges) && !(src(edge) in keys(nodeMap)) && !(dst(edge) in keys(nodeMap))
				push!(startingEdges, edge)
				nodeMap[src(edge)] = i
				nodeMap[dst(edge)] = i
				edgesAssigned[idx] = true
				clusters[i] = [edge]
				break
			end
		end
	end
	# as long as edges are not assigned, check if endpoints is already part of a neighborhood
	# if one is, assign edge to that neighborhood (arbitrarily giving priority to src)
	# if they aren't, skip edge and come back to it later
	while !all(edgesAssigned)
		for idx in shuffle(collect(eachindex(edgeList)))
			edge = edgeList[idx]
			if !edgesAssigned[idx]
				if src(edge) in keys(nodeMap)
					push!(clusters[nodeMap[src(edge)]], edge)
					edgesAssigned[idx] = true
					if !(dst(edge) in keys(nodeMap))
						nodeMap[dst(edge)] = nodeMap[src(edge)]
					end
				elseif dst(edge) in keys(nodeMap)
					push!(clusters[nodeMap[dst(edge)]], edge)
					edgesAssigned[idx] = true
					if !(src(edge) in keys(nodeMap))
						nodeMap[src(edge)] = nodeMap[dst(edge)]
					end
				end
			end
		end
	end
	return clusters
end

"""
	`flatten` : recursively concatenate all vectors in a vector of vectors
	Useful helper function for neighborhood continuity
"""
flatten{T}(a::Array{T,1}) = any(x->isa(x,Array),a)? flatten(vcat(map(flatten,a)...)): a

"""
	`findEdges`	: find all edges that begin and end in the provided list of nodes
"""
function findEdges(n::Network, nodeList::Vector{Int})
	nodeSet = Set(nodeList)
	edges = Set(Edge[])
	for node in nodeList
		for neighbor in out_neighbors(n.graph, node)
			if neighbor in nodeSet && n.roads[node, neighbor].roadType > 1
				push!(edges, Edge(node, neighbor))
			end
		end
	end
	return edges
end

"""
	`getFullPathEdges`	: given network timings and origin and destination, get path edges
	Wrapper for RoutingNetworks.getPathEdges that deals with particular case of road projection
	Args:
		t 		: network trip
		timings : current network timings
	Returns:
		Path for network trip as (Edge, Float) dictionary
"""
function getFullPathEdges(t::NetworkTrip, timings::NetworkTimings)
	sp = Dict(edge => 1. for edge in getPathEdges(timings, t.orig[2], t.dest[1]))
    if t.roadProj
        sp[Edge(t.orig[1], t.orig[2])] = t.orig[3]
        sp[Edge(t.dest[1], t.dest[2])] = t.dest[3]
    end
    return sp
end

"""
	`toPathEdgesDict`: given a trip and path (list of nodes), convert to (edge, weight) dictionary
"""
function toPathEdgesDict(t::NetworkTrip, path::Vector{Int})
	pathEdges = Dict(Edge(path[i], path[i+1]) => 1. for i = 1:(length(path)-1))
	if t.roadProj
        pathEdges[Edge(t.orig[1], t.orig[2])] = t.orig[3]
        pathEdges[Edge(t.dest[1], t.dest[2])] = t.dest[3]
    end
	return pathEdges
end
