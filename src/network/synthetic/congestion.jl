###################################################
## network/tools/congestion.jl
## Create networks with particular congestion patterns
###################################################

"""
	Creates a square grid where the center is twice as congested as the rest
	Args:
		- size: length of edge of square
"""
function centerCongestion(size::Int)
	n = squareNetwork(size)
	timings = roadTypeTimings(n)
	nodeList = div(size * (size+1), 4) + squareNodes(div(size, 2), size)
	for edge in findEdges(n, nodeList)
		timings.times[src(edge), dst(edge)] *= 2
	end
	timings = NetworkTimings(n, timings.times)
	return n, timings
end

"""
	Creates a square grid where two regions (in the corners) are heavily congested (one twice as slow as the rest, the other four times as slow)
	Args:
		- size: length of edge of square
"""
function twoCongestions(size::Int)
	n = squareNetwork(size)
	timings = roadTypeTimings(n)
	nodeList1 = squareNodes(div(size, 2) - 1, size) + size + 1
	nodeList2 = nodeList1 + (div(size, 2) - 1) * (size + 1)
	for edge in findEdges(n, nodeList1)
		timings.times[src(edge), dst(edge)] *= 2
	end
	for edge in findEdges(n, nodeList2)
		timings.times[src(edge), dst(edge)] *= 4
	end
	timings = NetworkTimings(n, timings.times)
	return n, timings
end

"""
	Creates a square grid where a peripheral road is twice as slow as the rest.
	Args:
		- `size`: length of square side
"""
function squareCongestion(size::Int)
	n = squareNetwork(size)
	timings = roadTypeTimings(n)
	nodeList = div(size, 8) * (size + 1) + setdiff(squareNodes(size - div(size, 8) * 2, size), (size + 1) + squareNodes(size - div(size, 8) * 2 - 2, size))
	for edge in findEdges(n, nodeList)
		timings.times[src(edge), dst(edge)] *= 2
	end
	timings = NetworkTimings(n, timings.times)
	return n, timings
end

"""
	Creates a square grid of edge length 'size' with 4 zones in increasing congestion
"""
function gradientCongestion(size::Int)
	n = squareNetwork(size)
	g = n.graph
	times = maxSpeedTimes(n)
	for u in vertices(g) 
		for v in out_neighbors(g, u)
			if v > u
				times[u,v] *= div(u-1, size^2/4) + 1
			end
		end
		for v in in_neighbors(g, u)
			if v > u
				times[v,u] *= div(u-1, size^2/4) + 1
			end
		end
	end
	timings = NetworkTimings(n, times)
	return n, timings
end

"""
	Helper function to construct squares
"""
function squareNodes(edge::Int, size::Int)
	nodeList = Int[]
	for i=1:edge
		append!(nodeList, collect(1:edge) + ((i-1) * size))
	end
	return nodeList
end
