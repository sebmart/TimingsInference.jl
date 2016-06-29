###################################################
## network/tools/edgeneighbors.jl
## functions to study local properties of edges
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
	`findNearEdgesSameType`	: find all edges that share a vertex with input e in network n and are of the same type, as a set of edges
"""
function findNearEdgesSameType(n::Network, e::Edge)
	orig = src(e)
	dest = dst(e)
	# find all edges that share a vertex with e
	nearEdges = [Edge(dest, newDest) for newDest in out_neighbors(n.graph, dest)]
	append!(nearEdges, [Edge(orig, newDest) for newDest in out_neighbors(n.graph, orig)])
	append!(nearEdges, [Edge(newOrig, orig) for newOrig in in_neighbors(n.graph, orig)])
	append!(nearEdges, [Edge(newOrig, dest) for newOrig in in_neighbors(n.graph, dest)])
	# remove duplicates and edge e itself
	nearEdges = Set(nearEdges)
	delete!(nearEdges, Edge(orig, dest))
	# remove edges not of same type as e
	for edge in nearEdges
		if n.roads[src(e),dst(e)].roadType != n.roads[src(edge),dst(edge)].roadType
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
