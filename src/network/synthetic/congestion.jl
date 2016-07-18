###################################################
## network/tools/congestion.jl
## Create networks with particular congestion patterns
###################################################

function centerCongestion()
	n = squareNetwork(8)
	timings = roadTypeTimings(n)
	nodeList = [19, 20, 21, 22, 27, 28, 29, 30, 35, 36, 37, 38, 43, 44, 45, 46]
	for edge in findEdges(n, nodeList)
		timings.times[src(edge), dst(edge)] *= 2
	end
	timings = NetworkTimings(n, timings.times)
	return n, timings
end

function twoCongestions()
	n = squareNetwork(8)
	timings = roadTypeTimings(n)
	nodeList1 = [10, 11, 12, 18, 19, 20, 26, 27, 28]
	nodeList2 = nodeList1 + 27
	for edge in findEdges(n, nodeList1)
		timings.times[src(edge), dst(edge)] *= 2
	end
	for edge in findEdges(n, nodeList2)
		timings.times[src(edge), dst(edge)] *= 3
	end
	timings = NetworkTimings(n, timings.times)
	return n, timings
end

function squareCongestion()
	n = squareNetwork(8)
	timings = roadTypeTimings(n)
	nodeList = [10, 11, 12, 13, 14, 15, 18, 23, 26, 31, 34, 39, 42, 47, 50, 51, 52, 53, 54, 55]
	for edge in findEdges(n, nodeList)
		timings.times[src(edge), dst(edge)] *= 2
	end
	timings = NetworkTimings(n, timings.times)
	return n, timings
end
