###################################################
## example/analyzePaths.jl
## Looking at path evolution when starting from random points
###################################################

using RoutingNetworks, TimingsInference, JLD;
stats = load("Outputs/stats-randomPathsOriginal.jld", "nwstats");
od = load("Outputs/nodePairsTotal.jld", "od");
n = loadTemplate("Manhattan");

tmpOD = Tuple{Int,Int}[];
srand(1991);
for (o,d) in shuffle(od)[1:10]
	println(o, " => ", d)
	push!(tmpOD, (o,d))
end

paths = load("Outputs/savedPathsVis.jld", "paths");

ntv = collect(IntSet(TimingsInference.flatten(paths[6])));
for (i,path) in enumerate(paths[6])
    println(stats[i].name)
    s = ShowPath(n, path)
    s.nodesToView = n.nodes[ntv]
    visualize(s)
end
