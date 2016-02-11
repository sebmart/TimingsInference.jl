###################################################
## statObject.jl
## Data type to save stats 
###################################################

"""
`StatObject` : abstract type that stores statistics about an algorithm run
must implement attributes:
- nIter : number of iterations
- times : array of time arrays, of length (nIter + 1), corresponding to the road times after each iteration.
		the first element is the set of road times used to initialize the algrithm
must implement methods:
- printStats : print a summary of statistics on the algorithm run
- plotStats : plot these stats in a nice way
"""

abstract StatObject

type RealDataStatObject <: StatObject
	nIter::Int
	times::Array{AbstractArray{Float64, 2}}

	testingMAE::Array{Float64,1}
	trainingMAEfull::Array{Float64,1}
	trainingMAEused::Array{Float64,1}
	function RealDataStatObject(initialTimes::AbstractArray{Float64, 2})
		obj = new()
		obj.nIter = 0
		obj.times = AbstractArray{Float64, 2}[]
		push!(obj.times, initialTimes)
		obj.testingMAE = Float64[]
		obj.trainingMAEfull = Float64[]
		obj.trainingMAEused = Float64[]
		return obj
	end
end