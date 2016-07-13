###################################################
## example/socp-metro.jl
## Testing reduced LP on urbanNetwork
###################################################

using RoutingNetworks, TimingsInference, JLD

n = urbanNetwork(8)
trueTimings = roadTypeTimings(n)
pb = noisyVirtualData(trueTimings, 0.4, timeStd = 20.)

initialTimes = uniformTimes(n);
s = LimitedPaths(pb, initialTimes, pathsPerTrip = 3, maxTrip = 10000)

nwstats = VirtNetworkStats[]
push!(nwstats, VirtNetworkStats("start", NetworkTimings(s), trueTimings, pb))
for i = 1:15
	doIteration!(s, method="socpCo")
	push!(nwstats, VirtNetworkStats("iter$i", NetworkTimings(s), trueTimings, pb))
end
