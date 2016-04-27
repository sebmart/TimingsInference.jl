###################################################
## network/dependentedges.jl
## find dependence relations between edges
###################################################

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
	Ainv = (eye(size(A)[1]) - A) ^ (-1)
	for (row, idx) in enumerate(independent)
		dependencies[row, idx] = 1.0
		dependencies[row, dependent] = Ainv * B[:, row] .* 1/n.roads[edgeList[idx]].distance
	end
	for idx in dependent
		dependencies[:, idx] = dependencies[:,idx] .* n.roads[edgeList[idx]].distance
	end
	return dependencies, edgeMap
end

function simplifyPath(path::Vector{Int}, dependencies::Array{Float64,2}, edgeMap::Dict{Tuple{Int,Int}, Int})
	newPath = zeros(size(dependencies)[1])
	for i = 1:(length(path)-1)
		newPath += dependencies[:,edgeMap[path[i], path[i+1]]]
	end
	return newPath
end

function pickIndepEdges(frac::Float64, n::Network)
	edges = collect(1:length(n.roads))
	shuf = shuffle(edges)
	independent = shuf[1:round(Int, frac * length(edges))]
	dependent = shuf[(round(Int, frac * length(edges))+1):end]
	return independent, dependent
end

function evaluateTime(dependency::Vector{Float64}, times::Vector{Float64})
	return dot(dependency, times)
end
