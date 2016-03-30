using RoutingNetworks, TimingsInference, JLD
n = loadTemplate("Manhattan")
trips = onlyWeekdays(inTimeWindow(load("/Users/arthurdelarue/Desktop/VRP/trips2015-01manhattan.jld", "trips"), 12, 0, 13, 0));

proj = NearestNode(n, trips)
ds = RandomSplit(trips, 0.8)
pb = NetworkData(proj, trainSet(ds))
pbTest = NetworkData(proj, testSet(ds))
s = HeuristicPaths(pb, maxTrip = 100000)
gt = TimingsFromNetwork(NetworkTimings(s), proj)
geostats = RealGeoStats[]
nwstats = RealNetworkStats[]
push!(geostats, RealGeoStats("start", gt, ds))
push!(nwstats, RealNetworkStats("start", NetworkTimings(s), pb, pbTest))

for i = 1:20
	doIteration!(s, method="heuristic")
	gt = TimingsFromNetwork(NetworkTimings(s), proj)
	push!(geostats, RealGeoStats("iter$i", gt, ds))
	push!(nwstats, RealNetworkStats("iter$i", NetworkTimings(s), pb, pbTest))
end
