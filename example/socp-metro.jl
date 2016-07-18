###################################################
## example/socp-metro.jl
## Testing reduced LP on urbanNetwork
###################################################

using RoutingNetworks, TimingsInference, JLD

n, trueTimings = squareCongestion()
# pb = noisyVirtualData(trueTimings, 1.0, timeStd = 5.)
pb = perfectVirtualData(trueTimings)

initialTimes = uniformTimes(n);
s = LimitedPaths(pb, initialTimes, pathsPerTrip = 3, maxTrip = 5000)

nwstats = VirtNetworkStats[]
push!(nwstats, VirtNetworkStats("start", NetworkTimings(s), trueTimings, pb))
for i = 1:10
	doIteration!(s, method="socpCo")
	push!(nwstats, VirtNetworkStats("iter$i", NetworkTimings(s), trueTimings, pb))
end
