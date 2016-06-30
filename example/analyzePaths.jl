###################################################
## example/analyzePaths.jl
## Looking at path evolution when starting from random points
###################################################

using RoutingNetworks, TimingsInference, JLD;
stats = load("/home/semartin/Tests/stats-randomPaths.jld", "nwstats");

n = loadTemplate("Manhattan");