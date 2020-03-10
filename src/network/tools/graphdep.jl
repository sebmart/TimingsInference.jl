###################################################
## network/tools/graphdep.jl
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
	edgeMap = Dict(edgeList[i] => i for i = eachindex(edgeList))
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
				B[row, findfirst(isequal(edge), independent)] = 1/nNearEdges
			else
				A[row, findfirst(isequal(edge), dependent)] = 1/nNearEdges
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
		minSize		: 	minimum value that a component must have (after sparsification) to be kept
	Returns:
		newDependency : vector summing to 1, with only numDeps nonzeros
"""
function sparsify(dependency::Vector{Float64}, numDeps::Int, minSize::Float64 = 0.05)
	# find largest components
	p = reverse(sortperm(dependency))
	newDependency = zeros(length(dependency))
	# renormalize
	total = sum(dependency[p[1:numDeps]])
	for i = 1:numDeps
		newDependency[p[i]] = dependency[p[i]]/total
	end
	# if smallest component is too small, re-sparsify with one less component
	if minimum(newDependency[newDependency .> 0]) < minSize
		return sparsify(dependency, numDeps-1, minSize)
	end
	return newDependency
end

"""
	`simplifyPath`: represent path as weighted sum of independent edges
	Args:
		path 		:	path as (Edge, Float) dictionary
		independent : 	list of independent edges
		dependencies:	matrix returned by findNetworkDependence
		edgeMap		:	dictionary, where keys are edges and values are the indices in the list of edges
	Returns:
		newPath		: 	path as (Edge, Float) dictionary, where the keys are the independent edges and the values are their weights in the path
"""
function simplifyPath(path::Dict{Edge, Float64}, independent::Vector{Edge}, dependencies::AbstractArray{Float64,2}, edgeMap::Dict{Edge, Int})
	newPath = Dict{Edge, Float64}()
	dep = zeros(size(dependencies)[1])
	for edge in keys(path)
		dep += path[edge] * dependencies[:,edgeMap[edge]]
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
	Args:
		n 				: Network object we are working with
		dependencies	: matrix returned by findNetworkDependence
		times 			: array of edge times
		independent 	: list of independent edges
		edgeMap 		: dictionary, where keys are edges and values are the indices in the list of edges
	Returns:
		newTimes 		: array of edge times, where times of independent edges are the same as in input times, and times of dependent edges are calculated from independent edges
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
	Args:
		paths		:	vector of vector of paths as edge=> weight dictionaries
		independent :	list of independent edges
		dependent 	:	list of dependent edges
		numEdges	:	number of edges to remove from independent set
		minIndep	:	minimum number of edges that the independent set must always contain
	Returns:
		newIndependent, newDependent : new sets of independent and dependent edges
"""
function updateIndependentEdges(paths::Vector{Vector{Dict{Edge, Float64}}}, independent::Vector{Edge}, dependent::Vector{Edge}, numEdges::Int = 10, minIndep::Int = 100)
	# check if edges can still be removed
	numToRemove = min(numEdges, length(independent) - minIndep)
	if numToRemove == 0
		return independent, dependent
	end
	indices = Dict(independent[i] => i for i=eachindex(independent))
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
