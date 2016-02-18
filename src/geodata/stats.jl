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
- updateStats! : given every possible kind of information needed, computes stats
- printStats : print a summary of statistics on the algorithm run
- plotStats : plot these stats in a nice way
"""

abstract Stats

function Base.show(io::IO, so::Stats)
	typeName = split(string(typeof(so)),".")[end]
	println(io, "$(typeName) for iteration $(so.nIter)")
end

type RealDataStats <: Stats
	nIter::Int
	times::Array{AbstractArray{Float64, 2}}
	sdict::Dict{AbstractString, Array{Union{Float64, Array{Float64,1}},1}}

	timeBound::Array{Float64,1}

	function RealDataStats()
		obj = new()
		obj.nIter = -1
		obj.times = AbstractArray{Float64, 2}[]
		obj.sdict = Dict{AbstractString, Array{Union{Float64, Array{Float64,1}},1}}(
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
			"testNetworkTripsBias" => Float64[],
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
	`printStats`: prints out statistic identified by statName stored in given Stats
	Optional argument outputFileName if you want to write this to a file instead
"""
function printStats(so::RealDataStats, statName::AbstractString; outputFileName = "")
	if outputFileName == ""
		println(so)
		println("Iteration\t$statName")
		if contains(statName, "bt")
			for i = 0:so.nIter
				println("$i ", so.sdict[statName][i + 1])
			end
		else
			for i = 0:so.nIter
				@printf("%d\t\t\t%.2f%%\n", i, so.sdict[statName][i + 1])
			end
		end
	else
		f = open(outputFileName, "w")
		write(f, so)
		write(f, "Iteration\t$statName")
		if contains(statName, "bt")
			for i = 0:so.nIter
				write(f, string("$i ", so.sdict[statName][i + 1], "\n"))
			end
		else
			for i = 0:so.nIter
				@printf(f, "%d\t\t\t%.2f%%\n", i, so.sdict[statName][i + 1])
			end
		end
		close(f)
	end
end

"""
	`plotStats`: plot relevant statistic, identified by statName, stored in given Stats object
"""
function plotStats(so::RealDataStats, statName::AbstractString)
	COLORS = ["red", "blue", "green", "orange", "black"]
	iterations = collect(0:so.nIter)
	if contains(statName, "bt")
		for (i, timeBound) in enumerate(so.timeBound)
			stat = [so.sdict[statName][j][i] for j=eachindex(so.sdict[statName])]
			plot(iterations, stat, color = COLORS[i % 5], label = string("<", 100 * time, "%"))
		end
	else
		plot(iterations, so.sdict[statName], color = "red", label = statName)
	end
	xlabel("Algorithm Step")
	ylabel(statName)
	title("Evolution of $(statName) with algorithm progress")
	legend()
end

"""
	`updateStats!`: Adds one round of stats to the Stats object
"""
function updateStats!(so::RealDataStats, s::IterativeState, proj::NetworkProjector, ds::DataSplit)
	so.nIter += 1
	push!(so.times, s.timings.times)
	push!(so.sdict["testTripsMAE"], 100 * testTripsMAE(s.timings, proj, ds))
	push!(so.sdict["trTripsMAE"], 100 * trTripsMAE(s.timings, proj, ds))
	push!(so.sdict["testTripsRMS"], 100 * testTripsRMS(s.timings, proj, ds))
	push!(so.sdict["trTripsRMS"], 100 * trTripsRMS(s.timings, proj, ds))
	push!(so.sdict["testTripsBias"], testTripsBias(s.timings, proj, ds))
	push!(so.sdict["trTripsBias"], trTripsBias(s.timings, proj, ds))
	push!(so.sdict["testNetworkTripsMAE"], 100 * testNetworkTripsMAE(s.timings, proj, ds))
	push!(so.sdict["trNetworkTripsMAE"], 100 * trNetworkTripsMAE(s.timings, proj, ds))
	push!(so.sdict["testNetworkTripsRMS"], 100 * testNetworkTripsRMS(s.timings, proj, ds))
	push!(so.sdict["trNetworkTripsRMS"], 100 * trNetworkTripsRMS(s.timings, proj, ds))
	push!(so.sdict["testNetworkTripsBias"], testNetworkTripsBias(s.timings, proj, ds))
	push!(so.sdict["trNetworkTripsBias"], trNetworkTripsBias(s.timings, proj, ds))
	push!(so.sdict["testTripsMAEbt"], 100 * testTripsMAEbyTime(s.timings, proj, ds, so.timeBound))
	push!(so.sdict["trTripsMAEbt"], 100 * trTripsMAEbyTime(s.timings, proj, ds, so.timeBound))
	push!(so.sdict["testTripsRMSbt"], 100 * testTripsRMSbyTime(s.timings, proj, ds, so.timeBound))
	push!(so.sdict["trTripsRMSbt"], 100 * trTripsRMSbyTime(s.timings, proj, ds, so.timeBound))
	push!(so.sdict["testTripsBiasbt"], testTripsBiasByTime(s.timings, proj, ds, so.timeBound))
	push!(so.sdict["trTripsBiasbt"], trTripsBiasByTime(s.timings, proj, ds, so.timeBound))
end