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
export findNetworkDependence, simplifyPath, pickIndepEdges, evaluateTime
#iterative
export IterativeState, doIteration!, LimitedPaths, heuristicPaths, updateState!, lpTimes, fraclpTimes, redlpTimes, mipTimes, heuristicTimes, socpTimes
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
include("network/statistics.jl")
include("network/virtualdata.jl")
include("network/virtualtimings.jl")
include("network/stats.jl")
include("network/dependentedges.jl")

include("network/iterative/state.jl")
include("network/iterative/limitedpaths.jl")

include("network/solvers/lptimes.jl")
include("network/solvers/socptimes.jl")
include("network/solvers/fraclptimes.jl")
include("network/solvers/redlptimes.jl")
include("network/solvers/miptimes.jl")
include("network/solvers/heuristicTimes.jl")

include("geo/trips.jl")
include("geo/data/nyctaxi.jl")
include("geo/data/filters.jl")

include("geo/projectors/networkprojector.jl")
include("geo/projectors/nearestnode.jl")
include("geo/projectors/avgradius.jl")

include("geo/timings/geotimings.jl")
include("geo/timings/fromnetwork.jl")
include("geo/timings/knn.jl")

include("geo/stats/datasplit.jl")
include("geo/stats/statistics.jl")
include("geo/stats/stats.jl")

include("visualization/showtimes.jl")

end # module
