###################################################
## network/stats.jl
## Data type to save networktrip stats
###################################################

"""
`NetworkStats` : abstract type that stores statistics about an algorithm run
must implement attributes:
- name : some information about the method used to generate this
- times : road times after each iteration.
- sdict : dictionary mapping stat names to relevant values
must implement methods:
- printStats : print a summary of statistics on the algorithm run
"""

abstract NetworkStats
function Base.show(io::IO, ns::NetworkStats)
	typeName = split(string(typeof(ns)),".")[end]
	println(io, "$(typeName): $(ns.name)")
end

"""
	`RealNetworkStats`: instance of NetworkStats, made for real trip data
"""
type RealNetworkStats <: NetworkStats
	name::AbstractString
	times::AbstractArray{Float64, 2}
	sdict::Dict{AbstractString, Float64}

	function RealNetworkStats(name::AbstractString, timings::NetworkTimings, trainingData::NetworkData, testingData::NetworkData)
		obj = new()
		obj.times = timings.times
		obj.name = name
		obj.sdict = Dict{AbstractString, Float64}(
			"trNetworkTripsLogError" => 100 * networkTripsLogError(timings, trainingData),
			"testNetworkTripsLogError" => 100 * networkTripsLogError(timings, testingData),
			"trNetworkTripsLogBias" => 100 * networkTripsLogBias(timings, trainingData),
			"testNetworkTripsLogBias" => 100 * networkTripsLogBias(timings, testingData))
		return obj
	end
end

"""
	`VirtNetworkStats`: instance of NetworkStats made for virtual data
"""
type VirtNetworkStats <: NetworkStats
	name::AbstractString
	times::AbstractArray{Float64,2}
	sdict::Dict{AbstractString, Float64}

	function VirtNetworkStats(name::AbstractString, timingsNew::NetworkTimings, timingsRef::NetworkTimings, data::NetworkData)
		obj = new()
		obj.times = timingsNew.times
		obj.name = name
		obj.sdict = Dict{AbstractString, Float64}(
			"tripsLogError" => 100 * networkTripsLogError(timingsNew, data),
			"tripsLogBias" => 100 * networkTripsLogBias(timingsNew, data),
			"allPathsLogError" => 100 * allPathsLogError(timingsRef, timingsNew),
			"allPathsLogBias" => 100 * allPathsLogBias(timingsRef, timingsNew),
			"roadTimeLogError" => 100 * roadTimeLogError(timingsRef, timingsNew),
			"roadTimeLogBias" => 100 * roadTimeLogBias(timingsRef, timingsNew))
		return obj
	end
end

"""
	`printStats`: takes in networkstats object, prints out summary of stats
"""
function printStats(so::NetworkStats)
	println(so)
	for statName in sort(collect(keys(so.sdict)))
		if contains(lowercase(statName), "bias") && !contains(lowercase(statName), "log")
			print(statName, ":\t")
			@printf("%.2f s\n", so.sdict[statName])
		else
			print(statName, ":\t")
			@printf("%.2f%%\n", so.sdict[statName])
		end
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
		if contains(lowercase(statName), "bias") && !contains(lowercase(statName), "log")
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
