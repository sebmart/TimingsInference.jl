###################################################
## TimingsInference.jl
## Package usings, includes and exports
###################################################

module TimingsInference

using RoutingNetworks, JuMP, Gurobi, MathProgBase, LightGraphs, Distributions, SFML
using  Base.Dates
import Colors
import RoutingNetworks: visualInit, visualEvent, visualUpdate

#general
export NetworkTimings, NetworkTrip
#timings data
export roadTypeTimings, maxSpeedTimes, uniformTimes, noisyVirtualData
export GeoTrip, fromNYCTaxiCSV, isRegular, removeOutliers, tripDistance, stats
export inPolygon, getPolygon
#iterative heuristic
export IterativeState, printStats, StaticIterative, doIteration!
#analysis
export tripsStd, tripsMAE, allPathsStd, allPathsMAE, roadTimeStd, roadTimeMAE
#visualization
export ShowTimes

include("networktimings.jl")

include("timingdata/createtimings.jl")
include("timingdata/generateRides.jl")
include("timingdata/geotrip.jl")
include("timingdata/nyctaxi.jl")

include("iterativeLP/iterativeState.jl")
include("iterativeLP/iterativeLP.jl")
include("iterativeLP/firstLP.jl")

include("analysis/statistics.jl")

include("visualization/showtimes.jl")

end # module
