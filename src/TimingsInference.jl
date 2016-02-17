###################################################
## TimingsInference.jl
## Package usings, includes and exports
###################################################

module TimingsInference

using RoutingNetworks, JuMP, Gurobi, MathProgBase, LightGraphs, Distributions, SFML
using Base.Dates, NearestNeighbors
try 
	using PyPlot
catch e
	println(e)
end
import Colors
import RoutingNetworks: visualInit, visualEvent, visualUpdate, inPolygon


#network data
export NetworkTimings, NetworkTrip, NetworkData
export roadTypeTimings, maxSpeedTimes, uniformTimes, noisyVirtualData
export tripsRMS, tripsMAE, allPathsRMS, allPathsMAE, roadTimeRMS, roadTimeMAE

#geo data
export GeoTrip, GeoData, NetworkProjector, NearestNode, AvgRadius
export DataSplit, RandomSplit
export StatObject, RealDataStatObject
export printStats, plotStats, update!
export inTimeWindow, onlyWeekdays, inPolygon, getPolygon, fromNYCTaxiCSV, isRegular, removeOutliers, tripDistance, stats
export preloadData!, getNetworkTrips, getTripTiming
#iterative heuristic
export IterativeState, printStats, doIteration!, FixedNumPathsPerTripState

#visualization
export ShowTimes

include("networkdata/networktimings.jl")
include("networkdata/createtimings.jl")
include("networkdata/generateRides.jl")
include("networkdata/statistics.jl")

include("geodata/geotrip.jl")
include("geodata/nyctaxi.jl")
include("geodata/networkprojector.jl")
include("geodata/splitdata.jl")
include("geodata/statobject.jl")

include("iterativeLP/iterativeState.jl")
include("iterativeLP/iterativeLP.jl")
include("iterativeLP/firstLP.jl")
include("iterativeLP/mip.jl")
include("iterativeLP/doubleLP.jl")

include("visualization/showtimes.jl")

end # module
