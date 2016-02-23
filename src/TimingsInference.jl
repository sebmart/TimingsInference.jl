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
export IterativeState, doIteration!, LimitedPaths, updateState!, lpTimes, lp2Times, mipTimes
#geo data
export GeoTrip, GeoData, NetworkProjector, NearestNode, AvgRadius
export DataSplit, RandomSplit
export Stats, RealDataStats
export printStats, plotStats, updateStats!
export inTimeWindow, onlyWeekdays, inPolygon, getPolygon, fromNYCTaxiCSV, isRegular, removeOutliers, tripDistance, stats
export preloadData!, getNetworkTrips, getTripTiming

#visualization
export ShowTimes

include("network/networktypes.jl")
include("network/statistics.jl")
include("network/virtualdata.jl")
include("network/virtualtimings.jl")

include("network/iterative/state.jl")
include("network/iterative/limitedpaths.jl")
include("network/iterative/lptimes.jl")
include("network/iterative/lp2times.jl")
include("network/iterative/miptimes.jl")

include("geodata/geotrip.jl")
include("geodata/nyctaxi.jl")
include("geodata/networkprojector.jl")
include("geodata/nearestnode.jl")
include("geodata/avgradius.jl")
include("geodata/splitdata.jl")
include("geodata/geostatdefs.jl")
include("geodata/stats.jl")

include("visualization/showtimes.jl")

end # module
