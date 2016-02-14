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

function Base.show(io::IO, so::StatObject)
	typeName = split(string(typeof(so)),".")[end]
	println(io, "$(typeName) for iteration $(nIter)")
end

type RealDataStatObject <: StatObject
	nIter::Int
	times::Array{AbstractArray{Float64, 2}}

	testingMAE::Array{Float64,1}
	trainingMAE::Array{Float64,1}
	function RealDataStatObject(initialTimes::AbstractArray{Float64, 2})
		obj = new()
		obj.nIter = 0
		obj.times = AbstractArray{Float64, 2}[]
		push!(obj.times, initialTimes)
		obj.testingMAE = Float64[]
		obj.trainingMAE = Float64[]
		return obj
	end
end

"""
	`printStats`: prints out relevant statistics stored in given StatObject
	Optional argument outputFileName if you want to write this to a file instead
"""
function printStats(so::RealDataStatObject; outputFileName = "")
	if outputFileName == ""
		println(so)
		println("Iteration\tTraining MAE\tTesting MAE")
		for i = 1:so.nIter
			@printf("%d\t\t\t%.2f%%\t%.2f%%\n", i, 100 * so.trainingMAE, 100 * so.testingMAE)
		end
	else
		f = open(outputFileName, "w")
		write(f, so)
		write(f, "Iteration\tTraining MAE\tTesting MAE\n")
		for i = 1:so.nIter
			@printf(f, "%d\t\t\t%.2f%%\t%.2f%%\n", i, 100 * so.trainingMAE, 100 * so.testingMAE)
		end
		close(f)
	end
end

"""
	`plotStats`: plot relevant statistics stored in given StatObject
"""
function plotStats(so::RealDataStatObject)
	iterations = collect(1:so.nIter)
	plot(iterations, so.trainingMAE, color = "red", label = "Training MAE")
	plot(iterations, so.testingMAE, color = "blue", label = "Testing MAE")
	xlabel("Iteration number")
	ylabel("MAE")
	title("Evolution of MAE with algorithm progress")
	legend()
end