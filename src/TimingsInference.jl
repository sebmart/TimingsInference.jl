###################################################
## TimingsInference.jl
## Package usings, includes and exports
###################################################

module TimingsInference

using RoutingNetworks, JuMP, Gurobi, Mosek, MathProgBase, LightGraphs, Distributions, SFML
using Base.Dates, NearestNeighbors
using PyPlot
using Colors

import RoutingNetworks: visualInit, visualEvent, inPolygon


#network
export NetworkTimings, NetworkTrip, NetworkData
export roadTypeTimings, randomTimings, maxSpeedTimes, uniformTimes, randomTimes
export noisyVirtualData, perfectVirtualData, simpleVirtualData
export findNetworkDependence, simplifyPath, evaluateTimes, getFullPathEdges
export findNearEdges, findNearEdgesSameType, clusterEdges
export centerCongestion, twoCongestions, squareCongestion, gradientCongestion
export typicalSpeeds

#iterative
export IterativeState, doIteration!, LimitedPaths, heuristicPaths, GreedyEdges, updateState!
export lpTimes, fraclpTimes, mipTimes, heuristicTimes, socpTimes, constantSpeedTimes
export socpTimesCont, socpTimesContNbhd

#geo data
export GeoTrip, GeoData, fromNYCTaxiCSV, removeOutliers, isRegular,  tripDistance, stats
export inTimeWindow, onlyWeekdays, inPolygon, getPolygon, DataSplit, RandomSplit, LocSplit, trainSet
export testSet, GeoStats, RealGeoStats, NetworkStats, RealNetworkStats, VirtNetworkStats
export printStats, plotStats
#projectors
export NetworkProjector, NearestNode, AvgRadius, NearestRoad
#geo-timings
export GeoTimings, TimingsFromNetwork, estimateTime, KnnTimings
#visualization
export ShowTimes, CompareTimes

include("network/networktypes.jl")

include("network/tools/edges.jl")
include("network/tools/graphdep.jl")

include("network/synthetic/virtualdata.jl")
include("network/synthetic/virtualtimings.jl")
include("network/synthetic/congestion.jl")

include("network/iterative/state.jl")
include("network/iterative/limitedpaths.jl")
include("network/iterative/greedy.jl")

include("network/stats/statistics.jl")
include("network/stats/stats.jl")

include("network/solvers/lp.jl")
include("network/solvers/socp.jl")
include("network/solvers/fraclp.jl")
include("network/solvers/mip.jl")
include("network/solvers/heuristic.jl")
include("network/solvers/roadtypespeed.jl")

include("network/tools/speeds.jl")


include("geo/trips.jl")
include("geo/data/nyctaxi.jl")
include("geo/data/filters.jl")

include("geo/projectors/networkprojector.jl")
include("geo/projectors/nearestnode.jl")
include("geo/projectors/avgradius.jl")
include("geo/projectors/nearestroad.jl")

include("geo/timings/geotimings.jl")

include("geo/stats/datasplit.jl")
include("geo/stats/statistics.jl")
include("geo/stats/stats.jl")

include("geo/timings/fromnetwork.jl")
include("geo/timings/knn.jl")

include("visualization/showtimes.jl")
include("visualization/comparetimes.jl")

end # module
