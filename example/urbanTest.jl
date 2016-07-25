###################################################
## example/urbanTest.jl
## Full tests of method on urban Network
###################################################

using RoutingNetworks, TimingsInference, JLD

NUMTRIPS = [100, 500, 1000, 5000, 10000]
NOISE = [5., 10., 20., 40.]

n = urbanNetwork(8)
trueTimings = roadTypeTimings(n);

# full perfect data
pb = perfectVirtualData(trueTimings, 0.)
initialTimes = trueTimings.times
s = LimitedPaths(pb, initialTimes, pathsPerTrip = 3, maxTrip = 40000)
nwstats = VirtNetworkStats[]
push!(nwstats, VirtNetworkStats("start", NetworkTimings(s), trueTimings, pb, s.pathDiff))
for i = 1:15
	doIteration!(s, method="socpCo")
	push!(nwstats, VirtNetworkStats("iter$i", NetworkTimings(s), trueTimings, pb, s.pathDiff))
	if s.pathDiff == 0.
		break
	end
end
inputError = TimingsInference.tripsLogError(trueTimings, s.trips)
save("fullPerfectDataPerfectPaths.jld", "nwstats", nwstats, "inputError", inputError)

initialTimes = randomTimes(n)
s = LimitedPaths(pb, initialTimes, pathsPerTrip = 3, maxTrip = 40000)
nwstats = VirtNetworkStats[]
push!(nwstats, VirtNetworkStats("start", NetworkTimings(s), trueTimings, pb, s.pathDiff))
for i = 1:15
	doIteration!(s, method="socpCo")
	push!(nwstats, VirtNetworkStats("iter$i", NetworkTimings(s), trueTimings, pb, s.pathDiff))
	if s.pathDiff == 0.
		break
	end
end
inputError = TimingsInference.tripsLogError(trueTimings, s.trips)
save("fullPerfectDataRandomPaths.jld", "nwstats", nwstats, "inputError", inputError)

## Incomplete perfect data
pb = perfectVirtualData(trueTimings)
initialTimes = randomTimes(n)
for nTrips in NUMTRIPS
	s = LimitedPaths(pb, initialTimes, pathsPerTrip = 3, maxTrip = nTrips)
	nwstats = VirtNetworkStats[]
	push!(nwstats, VirtNetworkStats("start", NetworkTimings(s), trueTimings, pb, s.pathDiff))
	for i = 1:50
		doIteration!(s, method="socpCo")
		push!(nwstats, VirtNetworkStats("iter$i", NetworkTimings(s), trueTimings, pb, s.pathDiff))
		if s.pathDiff == 0.
			break
		end
	end
	inputError = TimingsInference.tripsLogError(trueTimings, s.trips)
	save("perfectData$nTrips.jld", "nwstats", nwstats, "inputError", inputError)
end

## Incomplete noisy data
for noise in NOISE
	pb = noisyVirtualData(trueTimings, 1.0, timeStd = noise)
	initialTimes = randomTimes(n)
	for nTrips in NUMTRIPS
		s = LimitedPaths(pb, initialTimes, pathsPerTrip = 3, maxTrip = nTrips)
		nwstats = VirtNetworkStats[]
		push!(nwstats, VirtNetworkStats("start", NetworkTimings(s), trueTimings, pb, s.pathDiff))
		for i = 1:50
			doIteration!(s, method="socpCo")
			push!(nwstats, VirtNetworkStats("iter$i", NetworkTimings(s), trueTimings, pb, s.pathDiff))
			if s.pathDiff == 0.
				break
			end
		end
		inputError = TimingsInference.tripsLogError(trueTimings, s.trips)
		save("noisyData$noise-$nTrips.jld", "nwstats", nwstats, "inputError", inputError)
	end
end
