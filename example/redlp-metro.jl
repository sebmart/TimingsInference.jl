###################################################
## example/redlp-metro.jl
## Testing reduced LP on urbanNetwork
###################################################

using RoutingNetworks, TimingsInference, JLD

n = urbanNetwork(8)
trueTimings = roadTypeTimings(n)
pb = noisyVirtualData(trueTimings, 0.4)

initialTimes = uniformTimes(n);
s = GreedyEdges(pb, initialTimes, pathsPerTrip = 3, maxTrip = 100, numEdges = 20, numIter = 4)

nwstats = VirtNetworkStats[]
push!(nwstats, VirtNetworkStats("start", NetworkTimings(s), trueTimings, pb))
for i = 1:9
	doIteration!(s, method="socp")
	push!(nwstats, VirtNetworkStats("iter$i", NetworkTimings(s), trueTimings, pb))
end
