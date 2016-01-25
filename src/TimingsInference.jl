###################################################
## TimingsInference.jl
## Package usings, includes and exports
###################################################

module TimingsInference

using RoutingNetworks, JuMP, Gurobi, MathProgBase, LightGraphs, Distributions, SFML
using Base.Dates
import Colors
import RoutingNetworks: visualInit, visualEvent, visualUpdate


#network data
export NetworkTimings, NetworkTrip
export roadTypeTimings, maxSpeedTimes, uniformTimes, noisyVirtualData
export tripsStd, tripsMAE, allPathsStd, allPathsMAE, roadTimeStd, roadTimeMAE

#geo data
export GeoTrip, TripData
export inPolygon, getPolygon, fromNYCTaxiCSV, isRegular, removeOutliers, tripDistance, stats

#iterative heuristic
export IterativeState, printStats, StaticIterative, doIteration!
#visualization
export ShowTimes

include("networkdata/networktimings.jl")
include("networkdata/createtimings.jl")
include("networkdata/generateRides.jl")

include("geodata/geotrip.jl")
include("geodata/nyctaxi.jl")

include("iterativeLP/iterativeState.jl")
include("iterativeLP/iterativeLP.jl")
include("iterativeLP/firstLP.jl")

include("analysis/statistics.jl")

include("visualization/showtimes.jl")

end # module
