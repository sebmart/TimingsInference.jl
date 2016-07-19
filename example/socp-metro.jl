###################################################
## example/socp-metro.jl
## Testing reduced LP on urbanNetwork
###################################################

using RoutingNetworks, TimingsInference, JLD

n, trueTimings = squareCongestion(20)
pb = noisyVirtualData(trueTimings, 0.4, timeStd = 20.)
# pb = perfectVirtualData(trueTimings)

initialTimes = randomTimes(n);
s = LimitedPaths(pb, initialTimes, pathsPerTrip = 3, maxTrip = 1000)

nwstats = VirtNetworkStats[]
push!(nwstats, VirtNetworkStats("start", NetworkTimings(s), trueTimings, pb, s.pathDiff))
for i = 1:40
	doIteration!(s, method="socpCo")
	push!(nwstats, VirtNetworkStats("iter$i", NetworkTimings(s), trueTimings, pb, s.pathDiff))
	if s.pathDiff == 0.
		break
	end
end
