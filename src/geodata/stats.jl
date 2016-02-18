###################################################
## Stats.jl
## Data type to save stats 
###################################################

"""
`Stats` : abstract type that stores statistics about an algorithm run
must implement attributes:
- nIter : number of iterations
- times : array of time arrays, of length (nIter + 1), corresponding to the road times after each iteration.
		the first element is the set of road times used to initialize the algrithm
- sdict : dictionary mapping stat names to arrays containing relevant values
must implement methods:
- update! : given every possible kind of information needed, computes stats
- printStats : print a summary of statistics on the algorithm run
- plotStats : plot these stats in a nice way
"""

abstract Stats

function Base.show(io::IO, so::Stats)
	typeName = split(string(typeof(so)),".")[end]
	println(io, "$(typeName) for iteration $(so.nIter)")
	statList = collect(keys(so.sdict))
	println(io, "Contains following stats:")
	for stat in statList
		println(io, stat)
	end
end

type RealDataStats <: Stats
	nIter::Int
	times::Array{AbstractArray{Float64, 2}}
	sdict::Dict{AbstractString, Array{Union{Float64, Array{Float64,1}},1}}

	timeBound::Array{Float64,1}

	function RealDataStats(initialTimes::AbstractArray{Float64, 2})
		obj = new()
		obj.nIter = 0
		obj.times = AbstractArray{Float64, 2}[]
		push!(obj.times, initialTimes)
		obj.sdict = Dict{AbstractString, Array{Float64,1}}(
			"testTripsMAE" => Float64[],
			"trTripsMAE" => Float64[],
			"testTripsRMS" => Float64[],
			"trTripsRMS" => Float64[],
			"testTripsBias" => Float64[],
			"trTripsBias" => Float64[],
			"trNetworkTripsMAE" => Float64[],
			"testNetworkTripsMAE" => Float64[],
			"trNetworkTripsRMS" => Float64[],
			"testNetworkTripsRMS" => Float64[],
			"trNetworkTripsBias" => Float64[],
			"testNetworkTripsBias" => FLoat64[],
			"testTripsMAEbt" => Array{Float64,1}[],
			"trTripsMAEbt" => Array{Float64,1}[],
			"testTripsRMSbt" => Array{Float64,1}[],
			"trTripsRMSbt" => Array{Float64,1}[],
			"testTripsBiasbt" => Array{Float64,1}[],
			"trTripsBiasbt" => Array{Float64,1}[])
		obj.timeBound = [0.15, 0.25, 0.4, 0.5, 1.01]
		return obj
	end
end

"""
	`printStats`: prints out relevant statistics stored in given Stats
	Optional argument outputFileName if you want to write this to a file instead
"""
function printStats(so::RealDataStats; outputFileName = "")
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
	`plotStats`: plot relevant statistics stored in given Stats
"""
function plotStats(so::RealDataStats)
	iterations = collect(1:so.nIter)
	plot(iterations, so.trainingMAE, color = "red", label = "Training MAE")
	plot(iterations, so.testingMAE, color = "blue", label = "Testing MAE")
	xlabel("Iteration number")
	ylabel("MAE")
	title("Evolution of MAE with algorithm progress")
	legend()
end

"""
	`updateStats!`: not a required method, but useful. Adds one round of stats to the Stats
"""
function update!(so::RealDataStats, s::IterativeState, proj::NetworkProjector, ds::DataSplit)
	so.nIter += 1
	push!(so.times, times)
	push!(so.sdict["testTripsMAE"], testTripsMAE(s.timings, proj, ds))
	push!(so.sdict["trTripsMAE"], trTripsMAE(s.timings, proj, ds))
	push!(so.sdict["testTripsRMS"], testTripsRMS(s.timings, proj, ds))
	push!(so.sdict["trTripsRMS"], trTripsRMS(s.timings, proj, ds))
	push!(so.sdict["testTripsBias"], testTripsBias(s.timings, proj, ds))
	push!(so.sdict["trTripsBias"], trTripsBias(s.timings, proj, ds))
	push!(so.sdict["testNetworkTripsMAE"], testNetworkTripsMAE(s.timings, proj, ds))
	push!(so.sdict["trNetworkTripsMAE"], trNetworkTripsMAE(s.timings, proj, ds))
	push!(so.sdict["testNetworkTripsRMS"], testNetworkTripsRMS(s.timings, proj, ds))
	push!(so.sdict["trNetworkTripsRMS"], trNetworkTripsRMS(s.timings, proj, ds))
	push!(so.sdict["testNetworkTripsBias"], testNetworkTripsBias(s.timings, proj, ds))
	push!(so.sdict["trNetworkTripsBias"], trNetworkTripsBias(s.timings, proj, ds))
	push!(so.sdict["testTripsMAEbt"], testTripsMAEbyTime(s.timings, proj, ds, so.timeBound))
	push!(so.sdict["trTripsMAEbt"], trTripsMAEbyTime(s.timings, proj, ds, so.timeBound))
	push!(so.sdict["testTripsRMSbt"], testTripsRMSbyTime(s.timings, proj, ds, so.timeBound))
	push!(so.sdict["trTripsRMSbt"], trTripsRMSbyTime(s.timings, proj, ds, so.timeBound))
	push!(so.sdict["testTripsBiasbt"], testTripsBiasByTime(s.timings, proj, ds, so.timeBound))
	push!(so.sdict["trTripsBiasbt"], trTripsBiasByTime(s.timings, proj, ds, so.timeBound))
end