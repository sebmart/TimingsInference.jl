###################################################
## TimingsInference.jl
## Package usings, includes and exports
###################################################

module TimingsInference

using RoutingNetworks, JuMP, Gurobi, MathProgBase, LightGraphs, Distributions, SFML
using Base.Dates, NearestNeighbors
import Colors
import RoutingNetworks: visualInit, visualEvent, visualUpdate, inPolygon


#network data
export NetworkTimings, NetworkTrip, NetworkData
export roadTypeTimings, maxSpeedTimes, uniformTimes, noisyVirtualData
export tripsStd, tripsMAE, allPathsStd, allPathsMAE, roadTimeStd, roadTimeMAE

#geo data
export GeoTrip, GeoData, NetworkProjector, NearestNode
export inTimeWindow, inPolygon, getPolygon, fromNYCTaxiCSV, isRegular, removeOutliers, tripDistance, stats
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

include("iterativeLP/iterativeState.jl")
include("iterativeLP/iterativeLP.jl")
include("iterativeLP/firstLP.jl")
include("iterativeLP/mip.jl")
include("iterativeLP/doubleLP.jl")

include("visualization/showtimes.jl")

end # module
