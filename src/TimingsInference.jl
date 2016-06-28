###################################################
## TimingsInference.jl
## Package usings, includes and exports
###################################################

module TimingsInference

using RoutingNetworks, JuMP, Gurobi, Mosek, MathProgBase, LightGraphs, Distributions, SFML
using Base.Dates, NearestNeighbors
using PyPlot

import Colors
import RoutingNetworks: visualInit, visualEvent, inPolygon


#network
export NetworkTimings, NetworkTrip, NetworkData
export roadTypeTimings, maxSpeedTimes, uniformTimes, noisyVirtualData
export findNetworkDependence, simplifyPath, evaluateTimes
export findNearEdges, findNearEdgesSameType, clusterEdges
#iterative
export IterativeState, doIteration!, LimitedPaths, heuristicPaths, GreedyEdges, updateState!
export lpTimes, fraclpTimes, mipTimes, heuristicTimes, socpTimes 
export lpTimesCont, lpTimesContNbhd, socpTimesCont, socpTimesContNbhd
#geo data
export GeoTrip, GeoData, fromNYCTaxiCSV, removeOutliers, isRegular,  tripDistance, stats
export inTimeWindow, onlyWeekdays, inPolygon, getPolygon, DataSplit, RandomSplit, LocSplit, trainSet
export testSet, GeoStats, RealGeoStats, NetworkStats, RealNetworkStats, VirtNetworkStats
export printStats, plotStats
#projectors
export NetworkProjector, NearestNode, AvgRadius
#geo-timings
export GeoTimings, TimingsFromNetwork, estimateTime, KnnTimings
#visualization
export ShowTimes

include("network/networktypes.jl")
include("network/stats/statistics.jl")
include("network/stats/stats.jl")

include("network/tools/virtualdata.jl")
include("network/tools/virtualtimings.jl")
include("network/tools/edgeneighbors.jl")
include("network/tools/graphdep.jl")

include("network/iterative/state.jl")
include("network/iterative/limitedpaths.jl")
include("network/iterative/greedy.jl")

include("network/solvers/lp.jl")
include("network/solvers/socp.jl")
include("network/solvers/fraclp.jl")
include("network/solvers/mip.jl")
include("network/solvers/heuristic.jl")
include("network/solvers/lpCo.jl")
include("network/solvers/lpCoNbhd.jl")
include("network/solvers/socpCo.jl")
include("network/solvers/socpCoNbhd.jl")

include("geo/trips.jl")
include("geo/data/nyctaxi.jl")
include("geo/data/filters.jl")

include("geo/projectors/networkprojector.jl")
include("geo/projectors/nearestnode.jl")
include("geo/projectors/avgradius.jl")

include("geo/timings/geotimings.jl")

include("geo/stats/datasplit.jl")
include("geo/stats/statistics.jl")
include("geo/stats/stats.jl")

include("geo/timings/fromnetwork.jl")
include("geo/timings/knn.jl")

include("visualization/showtimes.jl")

end # module
