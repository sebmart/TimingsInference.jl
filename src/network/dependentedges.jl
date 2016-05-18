###################################################
## network/dependentedges.jl
## find dependence relations between edges
###################################################

"""
	`findNetworkDependence`: express independent edges as sum of dependent edges
	Args:
		n 			: 	the network 
		independent : 	list of independent edges (corresponding indices in the ordered list of edges in the network),
		dependent   : 	list of the remaining (dependent) edges
	Returns:
		dependencies:	a m by n matrix, where m is the number of independent edges and n is the total number of edges
						 each column corresponds to the weights of each independent edge in each edge
		edgeMap		:	dictionary, where keys are (orig, dest) pairs and values are the indices in the sorted list of edges
"""
function findNetworkDependence(n::Network, independent::Vector{Int}, dependent::Vector{Int})
	# initialize independent edges
	edgeList = sort(collect(keys(n.roads)))
	edgeMap = [edgeList[i] => i for i=eachindex(edgeList)]
	dependencies = zeros(length(independent), length(edgeList))

	# build matrix of dependencies
	A = zeros(length(dependent), length(dependent))
	B = zeros(length(dependent), length(independent))

	for (row, idx) in enumerate(dependent)
		(orig,dest) = edgeList[idx]
		nearEdges = [findfirst(edgeList, (dest, newDest)) for newDest in out_neighbors(n.graph, dest)]
		append!(nearEdges, [edgeMap[(orig, newDest)] for newDest in out_neighbors(n.graph, orig)])
		append!(nearEdges, [edgeMap[(newOrig, orig)] for newOrig in in_neighbors(n.graph, orig)])
		append!(nearEdges, [edgeMap[(newOrig, dest)] for newOrig in in_neighbors(n.graph, dest)])
		nearEdges = Set(nearEdges)
		delete!(nearEdges, edgeMap[(orig, dest)])
		nNearEdges = length(nearEdges)
		for edgeIdx in nearEdges
			if edgeIdx in independent
				B[row, findfirst(independent, edgeIdx)] = 1/nNearEdges
			else
				A[row, findfirst(dependent, edgeIdx)] = 1/nNearEdges
			end
		end
	end
	# perform matrix inversion
	Ainv = (eye(size(A)[1]) - A) ^ (-1)
	# create dependency matrix
	for (row, idx) in enumerate(independent)
		dependencies[row, idx] = 1.0
		dependencies[row, dependent] = Ainv * B[:, row] .* 1/n.roads[edgeList[idx]].distance
	end
	for idx in dependent
		dependencies[:, idx] = dependencies[:,idx] .* n.roads[edgeList[idx]].distance
	end
	return dependencies, edgeMap
end

"""
	`simplifyPath`: represent path as vector, where each element is the weight of the corresponding independent edge
	Args:
		path 		:	path as list of nodes
		dependencies:	matrix returned by findNetworkDependence
		edgeMap		:	dictionary, where keys are (orig, dest) pairs and values are the indices in the sorted list of edges
	Returns:
		newPath		: a vector of length the number independent edges
"""
function simplifyPath(path::Vector{Int}, dependencies::Array{Float64,2}, edgeMap::Dict{Tuple{Int,Int}, Int})
	newPath = zeros(size(dependencies)[1])
	for i = 1:(length(path)-1)
		newPath += dependencies[:,edgeMap[path[i], path[i+1]]]
	end
	return newPath
end

"""
	`pickIndepEdges`: pick random independent edges in the graph
	Args:
		frac		:	fraction of independent edges
		n 			: 	the network
	Returns:
		independent	:	list of independent edges
		dependent 	: 	list of dependent edges
"""
function pickIndepEdges(frac::Float64, n::Network)
	edges = collect(1:length(n.roads))
	shuf = shuffle(edges)
	independent = shuf[1:round(Int, frac * length(edges))]
	dependent = shuf[(round(Int, frac * length(edges))+1):end]
	return independent, dependent
end

"""
	`evaluateTime` : given time values for independent edges (times), return time of dependent edge (specified by dependency)
"""
function evaluateTime(dependency::Vector{Float64}, times::Vector{Float64})
	return dot(dependency, times)
end

"""
	`fakeTimes`	:	this is a temporary fix to plot independent/dependent edges using ShowTimes
	Keep it in for now, but the objective is to have this be deprecated by the next PR
"""
function fakeTimes(n::Network, independent::Vector{Int}, edgeMap::Dict{Tuple{Int,Int}, Int})
	times = uniformTimes(n);
	for i = 1:nNodes(n), j = out_neighbors(n.graph, i)
		if times[i,j] > 0
			if edgeMap[(i,j)] in independent
				times[i,j] = n.roads[(i,j)].distance/1000
			else
				times[i,j] = n.roads[(i,j)].distance
			end
		end
	end
	return times
end