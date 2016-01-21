###################################################
## TimingsInference.jl
## Package usings, includes and exports
###################################################

module TimingsInference

using RoutingNetworks, JuMP, Gurobi, MathProgBase, LightGraphs, Distributions

#general
export NetworkTimings, NetworkTrip
#network data
export roadTypeTimings, maxSpeedTimes, uniformTimes, noisyVirtualData
#iterative heuristic
export IterativeState, StaticIterative, doIteration!
#analysis
export tripsStd, tripsMAE, allPathsStd, allPathsMAE, roadTimeStd, roadTimeMAE

include("networktimings.jl")

include("networkdata/createtimings.jl")
include("networkdata/generateRides.jl")

include("iterativeLP/iterativeState.jl")
include("iterativeLP/iterativeLP.jl")
include("iterativeLP/firstLP.jl")

include("analysis/statistics.jl")

end # module
