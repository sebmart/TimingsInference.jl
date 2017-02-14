###################################################
## network/stats/stats.jl
## Data type to save networktrip stats
###################################################

"""
`NetworkStats` : abstract type that stores statistics about an algorithm run
must implement attributes:
- `name` : some information about the method used to generate this
- `times` : road times after each iteration.
- `sdict` : dictionary mapping stat names to relevant values
must implement methods:
- `printStats` : print a summary of statistics on the algorithm run
"""

abstract NetworkStats
function Base.show(io::IO, ns::NetworkStats)
	typeName = split(string(typeof(ns)),".")[end]
	println(io, "$(typeName): $(ns.name)")
end

"""
	`RealNetworkStats`: instance of NetworkStats, made for real trip data. This corresponds
	to the case where true time information is not available.
"""
type RealNetworkStats <: NetworkStats
	name::AbstractString
	times::AbstractArray{Float64, 2}
	sdict::Dict{AbstractString, Float64}

	function RealNetworkStats(name::AbstractString, timings::NetworkTimings, trainingData::NetworkData, testingData::NetworkData, pathDiff::Float64 = -1.)
		obj = new()
		obj.times = timings.times
		obj.name = name
		obj.sdict = Dict{AbstractString, Float64}(
			"trNetworkTripsLogError" => nwTripsLogError(timings, trainingData),
			"testNetworkTripsLogError" => nwTripsLogError(timings, testingData),
			"trNetworkTripsLogBias" => nwTripsLogBias(timings, trainingData),
			"testNetworkTripsLogBias" => nwTripsLogBias(timings, testingData),
			"pathDiff" => pathDiff)
		return obj
	end
end

RealNetworkStats(name, state::IterativeState, testingData) =
RealNetworkStats(name, state.timings, state.data, testingData, state.pathDiff)

"""
	`VirtNetworkStats`: instance of NetworkStats made for virtual data
"""
type VirtNetworkStats <: NetworkStats
	name::AbstractString
	times::AbstractArray{Float64,2}
	sdict::Dict{AbstractString, Float64}

	function VirtNetworkStats(name::AbstractString, timingsNew::NetworkTimings, timingsRef::NetworkTimings, data::NetworkData, pathDiff::Float64 = -1.)
		obj = new()
		obj.times = timingsNew.times
		obj.name = name
		obj.sdict = Dict{AbstractString, Float64}(
			"tripsLogError" => nwTripsLogError(timingsRef, data),
			"tripsLogBias" => nwTripsLogBias(timingsNew, data),
			"tripsRealLogError" => nwTripsRealLogError(timingsRef, timingsNew, data),
			"tripsRealLogBias" => nwTripsRealLogBias(timingsRef, timingsNew, data),
			"allPathsLogError" => allPathsLogError(timingsRef, timingsNew),
			"allPathsLogBias" => allPathsLogBias(timingsRef, timingsNew),
			"roadTimeLogError" => roadTimeLogError(timingsRef, timingsNew),
			"roadTimeLogBias" => roadTimeLogBias(timingsRef, timingsNew),
			"pathDiff" => pathDiff)
		return obj
	end
end

VirtNetworkStats(name, state::IterativeState, timingsRef) =
VirtNetworkStats(name, state.timings, timingsRef, state.data, state.pathDiff)

"""
	`printStats`: takes in networkstats object, prints out summary of stats
"""
function printStats(so::NetworkStats)
	println(so)
	statNames = sort(collect(keys(so.sdict)))
	firstColumnWidth = maximum([length(name) for name in statNames])

	for statName in statNames
		print(statName, " " ^ (2 + firstColumnWidth - length(statName)))
		@printf("%.6f\n", so.sdict[statName])
	end
end

"""
	`printStats`: print stat evolution from list of NetworkStats objects
"""
function printStats{T <: NetworkStats}(stats::Vector{T}, statName::AbstractString)
	# check if stat is valid and if timebounds are same
	for so in stats
		if !(statName in collect(keys(so.sdict)))
			error("Statistic not found")
		end
	end
	println(statName)
	for so in stats
		if statName == "pathDiff"
			@printf("%s\t%.2f\n", so.name, so.sdict[statName])
		elseif contains(lowercase(statName), "bias") && !contains(lowercase(statName), "log")
			@printf("%s\t%.0fs\n", so.name, so.sdict[statName])
		else
			@printf("%s\t%.2f%%\n", so.name, so.sdict[statName])
		end
	end
end

"""
	`plotStats`: plot stat evolution from list of NetworkStats objects
"""
function plotStats{T <: NetworkStats}(stats::Vector{T}, statName::AbstractString)
	# check if stat is valid and if timebounds are same
	for so in stats
		if !(statName in collect(keys(so.sdict)))
			error("Statistic not found")
		end
	end
	x = collect(eachindex(stats))
	xlabels = [so.name for so in stats]
	plot(x, [so.sdict[statName] for so in stats], "o", color = "red")
	xticks(x, xlabels)
	xlabel("Method used")
	ylabel(statName)
	title("$(statName)")
	margins(0.2)
end
