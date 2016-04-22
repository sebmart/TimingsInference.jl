###################################################
## network/dependentedges.jl
## find dependence relations between edges
###################################################

function findNetworkDependence(n::Network, independent::BitArray{2}, k::Int)
	# initialize independent edges
	roads = n.roads
	dependencies = Dict{Tuple{Int,Int}, Dict{Tuple{Int,Int},Float64}}()
	independentEdges = Tuple{Int,Int}[]
	for (orig,dest) in keys(roads)
		if independent[orig,dest]
			push!(independentEdges, (orig,dest))
			dependencies[orig,dest] = Dict{Tuple{Int,Int}, Float64}((orig,dest) => 1.0)
		end
	end
	for (orig,dest) in keys(roads)
		if !(independent[orig,dest])
			dependencies[orig,dest] = Dict{Tuple{Int,Int}, Float64}([indepEdge => roads[(orig,dest)].distance/(length(independentEdges) * roads[indepEdge].distance) for indepEdge in independentEdges])
		end
	end
	for j = 1:k
		for (orig, dest) in keys(dependencies)
			if !independent[orig, dest]
				nearEdges = [(dest, newDest) for newDest in out_neighbors(n.graph, dest)]
				append!(nearEdges, [(newOrig, orig) for newOrig in in_neighbors(n.graph, orig)])
				nearEdges = Set(nearEdges)
				nNearEdges = length(nearEdges)
				dependencies[orig,dest] = Dict{Tuple{Int,Int}, Float64}()
				for edge in nearEdges
					for neighbor in keys(dependencies[edge])
						if neighbor in keys(dependencies[orig,dest])
							dependencies[orig,dest][neighbor] += dependencies[edge][neighbor] * roads[(orig,dest)].distance/(nNearEdges * roads[neighbor].distance)
						else
							dependencies[orig,dest][neighbor] = dependencies[edge][neighbor] * roads[(orig,dest)].distance/(nNearEdges * roads[neighbor].distance)
						end
					end
				end
			end
		end
	end
	return dependencies
end

function simplifyPath(path::Vector{Int}, dependencies::Dict{Tuple{Int,Int}, Dict{Tuple{Int,Int},Float64}})
	newPath = Dict{Tuple{Int,Int},Float64}()
	for i = 1:(length(path)-1)
		for edge in keys(dependencies[path[i], path[i+1]])
			if edge in keys(newPath)
				newPath[edge] += dependencies[path[i], path[i+1]][edge]
			else
				newPath[edge] = dependencies[path[i], path[i+1]][edge]
			end
		end
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
