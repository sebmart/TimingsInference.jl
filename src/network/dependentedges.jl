###################################################
## network/dependentedges.jl
## find dependence relations between edges
###################################################

function findNetworkDependence(n::Network, independent::BitArray{2}, k::Int)
	# initialize independent edges
	roads = n.roads
	dependencies = Dict{Tuple{Int,Int}, Vector{Float}}()
	independentEdges = Tuple{Int,Int}[]
	for (orig,dest) in keys(roads)
		if independent[orig,dest]
			push!(independentEdges, (orig,dest))
			dependencies[orig,dest] = zeros(length(independentEdges))
			dependencies[orig,dest][length()]
		end
	end
	for (orig,dest) in keys(roads)
		if independent[orig,dest]
			dependencies[orig,dest] = zeros(length(independentEdges))
			dependencies[orig,dest][findfirst(independentEdges), (orig, dest)] = 1.0
		else
			dependencies[orig,dest] = [roads[(orig,dest)].distance/(length(independentEdges) * roads[indepEdge].distance) for indepEdge in independentEdges]
		end
	end
	for j = 1:k
		for (orig, dest) in keys(dependencies)
			if !independent[orig, dest]
				nearEdges = [(dest, newDest) for newDest in out_neighbors(n.graph, dest)]
				append!(nearEdges, [(newOrig, orig) for newOrig in in_neighbors(n.graph, orig)])
				nearEdges = Set(nearEdges)
				nNearEdges = length(nearEdges)
				dependencies[orig,dest] = zeros(length(independentEdges))
				for edge in nearEdges
					dependencies[orig,dest].+=dependencies[edge].*(roads[orig,dest].distance/(nNearEdges*roads[edge].distance))
				end
			end
		end
	end
	return dependencies, independentEdges
end

function simplifyPath(path::Vector{Int}, dependencies::Dict{Tuple{Int,Int}, Vector{Float}})
	newPath = zeros(dependencies[(path[1], path[2])])
	for i = 1:(length(path)-1)
		newPath .+= dependencies[(path[i], path[i+1])]
	end
	return newPath
end

function random2DBits(freqOnes::Float64, n::Int)
	ar = falses(n, n)
	for i = 1:n, j = 1:n
		if rand() < freqOnes
			ar[i,j] = true
		end
	end
	return ar
end

function evaluateTime(dependency::Vector{Float64}, times::Vector{Float64})
	return dot(dependency, times)
end
