###################################################
## TimingsInference.jl
## Package usings, includes and exports
###################################################

module TimingsInference

using RoutingNetworks, JuMP, Gurobi, MathProgBase, LightGraphs, Distributions

export NetworkTimings, NetworkTrip

export roadTypeTimings, maxSpeedTimes, noisyVirtualData

export IterativeState, StaticIterative, iterativeLP


include("networktimings.jl")

include("networkdata/createtimings.jl")
include("networkdata/generateRides.jl")

include("iterativeLP/iterativeState.jl")
include("iterativeLP/iterativeLP.jl")
include("iterativeLP/firstLP.jl")

end # module
