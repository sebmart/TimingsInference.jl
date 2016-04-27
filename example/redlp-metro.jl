###################################################
## example/redlp-metro.jl
## Testing reduced LP on urbanNetwork
###################################################

using RoutingNetworks, TimingsInference, JLD

n = urbanNetwork(8)
trueTimings = roadTypeTimings(n)
pb = noisyVirtualData(trueTimings, 0.4)

initialTimes = uniformTimes(n);
s = LimitedPaths(pb, initialTimes, pathsPerTrip = 3, maxTrip = 10000)

nwstats = VirtNetworkStats[]
push!(nwstats, VirtNetworkStats("start", NetworkTimings(s), trueTimings, pb))
for i = 1:5
	doIteration!(s, method="redlp")
	push!(nwstats, VirtNetworkStats("iter$i", NetworkTimings(s), trueTimings, pb))
end
