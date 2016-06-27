###################################################
## network/tools/dependentedges.jl
## find dependence relations between edges
###################################################

"""
	`findNetworkDependence`: express independent edges as sum of dependent edges
	Args:
		n 			: 	the network 
		independent : 	list of independent edges
		dependent   : 	list of the remaining (dependent) edges
		numDeps		: 	optional, sparsity parameter
	Returns:
		dependencies:	a m by n matrix, where m is the number of independent edges and n is the total number of edges
						 each column corresponds to the weights of each independent edge in each edge
		edgeMap		:	dictionary, where keys are (orig, dest) pairs and values are the indices in the sorted list of edges
"""
function findNetworkDependence(n::Network, independent::Vector{Edge}, dependent::Vector{Edge}; numDeps::Int = 3)
	# initialize independent edges
	edgeList = collect(edges(n.graph))
	edgeMap = [edgeList[i] => i for i = eachindex(edgeList)]
	dep = zeros(length(independent), length(edgeList))
	dependencies = spzeros(length(independent), length(edgeList))
	#special case of all independent edges
	if length(dependent) == 0
		return speye(length(edgeList)), edgeMap
	end
	# build matrix of dependencies
	A = zeros(length(dependent), length(dependent))
	B = zeros(length(dependent), length(independent))
	for (row, edge) in enumerate(dependent)
		nearEdges = findNearEdges(n, edge)
		nNearEdges = length(nearEdges)
		for edge in nearEdges
			if edge in independent
				B[row, findfirst(independent, edge)] = 1/nNearEdges
			else
				A[row, findfirst(dependent, edge)] = 1/nNearEdges
			end
		end
	end
	# perform matrix inversion
	Ainv = (eye(size(A)[1]) - A) ^ (-1)
	# create dependency matrix
	depIndices = [edgeMap[edge] for edge in dependent]
	for (row, edge) in enumerate(independent)
		dep[row, edgeMap[edge]] = 1.0
		dep[row, depIndices] = Ainv * B[:, row]
	end
	# sparsify dependency matrix
	for edge in dependent
		dep[:, edgeMap[edge]] = sparsify(dep[:,edgeMap[edge]], numDeps)
	end
	# Multiply and divide by appropriate distances to transform velocity relations to time relations
	for (row, edge) in enumerate(independent)
		dep[row, depIndices] = dep[row, depIndices] .* 1/n.roads[(src(edge), dst(edge))].distance
	end
	for edge in dependent
		dep[:, edgeMap[edge]] = dep[:,edgeMap[edge]] .* n.roads[(src(edge), dst(edge))].distance
	end
	for i in eachindex(independent), j in eachindex(edgeList)
		if dep[i,j] > 0
			dependencies[i,j] = dep[i,j]
		end
	end
	return dependencies, edgeMap
end

"""
	`sparsify` : given a vector of dependences summing to 1, identify main components, reduce all others to 0 and renormalize
	Args:
		dependency 	:	vector summing to 1
		numDeps	  	:	number of components to keep, > 1
"""
function sparsify(dependency::Vector{Float64}, numDeps::Int)
	p = reverse(sortperm(dependency))
	newDependency = zeros(length(dependency))
	total = sum(dependency[p[1:numDeps]])
	for i = 1:numDeps
		newDependency[p[i]] = dependency[p[i]]/total
	end
	return newDependency
end

"""
	`simplifyPath`: represent path as weighted sum of independent edges
	Args:
		path 		:	path as list of edges
		independent : 	list of independent edges
		dependencies:	matrix returned by findNetworkDependence
		edgeMap		:	dictionary, where keys are edges and values are the indices in the list of edges
	Returns:
		newPath		: 	path as (Edge, Float) dictionary, where the keys are the independent edges and the values are their weights in the path
"""
function simplifyPath(path::Vector{Edge}, independent::Vector{Edge}, dependencies::AbstractArray{Float64,2}, edgeMap::Dict{Edge, Int})
	newPath = Dict{Edge, Float64}()
	dep = zeros(size(dependencies)[1])
	for edge in path
		dep += dependencies[:,edgeMap[edge]]
	end
	for (i, weight) in enumerate(dep)
		if weight > 0
			newPath[independent[i]] = weight
		end
	end
	return newPath
end

"""
	`evaluateTime` : given time values for independent edges (times), return time of dependent edge (specified by dependency)
"""
function evaluateTimes(n::Network, dependencies::AbstractArray{Float64,2}, times::AbstractArray{Float64,2}, independent::Vector{Edge}, edgeMap::Dict{Edge, Int})
	edgeList = collect(edges(n.graph))
	newTimes = spzeros(Float64, size(times)[1], size(times)[2])
	for (i, edge) in enumerate(edgeList)
		newTimes[src(edge), dst(edge)] = sum([times[src(ind), dst(ind)] * dependencies[idx,i] for (idx, ind) in enumerate(independent)])
	end
	return newTimes
end

"""
	`updateIndependentEdges`	: given set of paths, update independent set of edges
"""
function updateIndependentEdges(paths::Vector{Vector{Dict{Edge, Float64}}},independent::Vector{Edge},dependent::Vector{Edge},numEdges::Int = 10, minIndep::Int = 100)
	# check if edges can still be removed
	numToRemove = min(numEdges, length(independent) - minIndep)
	if numToRemove == 0
		return independent, dependent
	end
	indices = [independent[i] => i for i=eachindex(independent)]
	totalWeight = zeros(length(independent))
	for pathVector in paths, path in pathVector, edge in keys(path)
		totalWeight[indices[edge]] += path[edge]
	end
	# fgind lowest weighted edges
	p = sortperm(totalWeight)
	newIndependent = independent[p[(numToRemove+1):end]]
	newDependent = dependent
	append!(newDependent, independent[p[1:numToRemove]])
	sort!(newDependent)
	return newIndependent, newDependent
end

"""
	`findNearEdges` : find all edges that share a vertex with input e in network n, as a set of edges
"""
function findNearEdges(n::Network, e::Edge)
	orig = src(e)
	dest = dst(e)
	nearEdges = [Edge(dest, newDest) for newDest in out_neighbors(n.graph, dest)]
	append!(nearEdges, [Edge(orig, newDest) for newDest in out_neighbors(n.graph, orig)])
	append!(nearEdges, [Edge(newOrig, orig) for newOrig in in_neighbors(n.graph, orig)])
	append!(nearEdges, [Edge(newOrig, dest) for newOrig in in_neighbors(n.graph, dest)])
	nearEdges = Set(nearEdges)
	delete!(nearEdges, Edge(orig, dest))
	return nearEdges
end

"""
	`findNearEdgesSameType`	: find all edges that share a vertex with input e in network n and are of the same type, as a set of edges
"""
function findNearEdgesSameType(n::Network, e::Edge)
	orig = src(e)
	dest = dst(e)
	nearEdges = [Edge(dest, newDest) for newDest in out_neighbors(n.graph, dest)]
	append!(nearEdges, [Edge(orig, newDest) for newDest in out_neighbors(n.graph, orig)])
	append!(nearEdges, [Edge(newOrig, orig) for newOrig in in_neighbors(n.graph, orig)])
	append!(nearEdges, [Edge(newOrig, dest) for newOrig in in_neighbors(n.graph, dest)])
	nearEdges = Set(nearEdges)
	delete!(nearEdges, Edge(orig, dest))
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
function clusterEdges(n::Network, nNeighbors::Int=50)
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

flatten{T}(a::Array{T,1}) = any(map(x->isa(x,Array),a))? flatten(vcat(map(flatten,a)...)): a
