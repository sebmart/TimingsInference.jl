###################################################
## TimingsInference.jl
## Package usings, includes and exports
###################################################

module TimingsInference

using RoutingNetworks, JuMP, Gurobi, MathProgBase, LightGraphs, Distributions, SFML
using Base.Dates, NearestNeighbors
using PyPlot

import Colors
import RoutingNetworks: visualInit, visualEvent, inPolygon


#network
export NetworkTimings, NetworkTrip, NetworkData
export roadTypeTimings, maxSpeedTimes, uniformTimes, noisyVirtualData
export tripsRMS, tripsMAE, allPathsRMS, allPathsMAE, roadTimeRMS, roadTimeMAE
#iterative
export IterativeState, doIteration!, LimitedPaths, heuristicPaths, updateState!, lpTimes, lp2Times, redlpTimes, mipTimes, heuristicTimes
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

include("network/iterative/state.jl")
include("network/iterative/limitedpaths.jl")
include("network/iterative/lptimes.jl")
include("network/iterative/lp2times.jl")
include("network/iterative/redlptimes.jl")
include("network/iterative/miptimes.jl")
include("network/iterative/heuristicTimes.jl")

include("geo/trips.jl")
include("geo/nyctaxi.jl")
include("geo/datafilters.jl")


include("geo/projectors/networkprojector.jl")
include("geo/projectors/nearestnode.jl")
include("geo/projectors/avgradius.jl")
include("geo/datasplit.jl")

include("geo/timings/geotimings.jl")
include("geo/timings/fromnetwork.jl")
include("geo/timings/knn.jl")

include("geo/statistics.jl")
include("geo/stats.jl")

include("visualization/showtimes.jl")

end # module
