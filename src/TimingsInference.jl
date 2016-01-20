###################################################
## TimingsInference.jl
## Package usings, includes and exports
###################################################

module TimingsInference

using RoutingNetworks, JuMP, Gurobi, MathProgBase, LightGraphs

export NetworkTimings, NetworkTrip

export roadTypeTimings, maxSpeedTimes

export IterativeState, StaticIterative, iterativeLP


include("networktimings.jl")

include("networkdata/createtimings.jl")

include("iterativeLP/iterativeState.jl")
include("iterativeLP/iterativeLP.jl")
include("iterativeLP/firstLP.jl")

end # module
