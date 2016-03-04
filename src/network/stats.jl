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
	println(io, "$(typeName): $(so.name)")
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
			"trNetworkTripsMAE" => 100 * networkTripsMAE(timings, trainingData),
			"testNetworkTripsMAE" => 100 * networkTripsMAE(timings, testingData),
			"trNetworkTripsRMS" => 100 * networkTripsRMS(timings, trainingData),
			"testNetworkTripsRMS" => 100 * networkTripsRMS(timings, testingData),
			"trNetworkTripsBias" => networkTripsBias(timings, trainingData),
			"testNetworkTripsBias" => networkTripsBias(timings, trainingData))
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
			"tripsMAE" => 100 * networkTripsMAE(timingsNew, data),
			"tripsRMS" => 100 * networkTripsRMS(timingsNew, data),
			"tripsBias" => networkTripsBias(timingsNew, data),
			"allPathsMAE" => 100 * allPathsMAE(timingsRef, timingsNew),
			"allPathsRMS" => 100 * allPathsRMS(timingsRef, timingsNew),
			"allPathsBias" => allPathsBias(timingsRef, timingsNew),
			"roadTimeMAE" => 100 * roadTimeMAE(timingsRef, timingsNew),
			"roadTimeRMS" => 100 * roadTimeRMS(timingsRef, timingsNew)
			"roadTimeBias" => roadTimeBias(timingsRef, timingsNew))
		return obj
	end
end

"""
	`printStats`: takes in networkstats object, prints out summary of stats
"""
function printStats(so::NetworkStats)
	println(so)
	for statName in sort(collect(keys(so.sdict)))
		if contains(lowercase(statName), "bias")
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
function printStats(stats::Vector{NetworkStats}, statName::AbstractString)
	# check if stat is valid and if timebounds are same
	for so in stats
		if !(statName in collect(keys(so.sdict)))
			error("Statistic not found")
		end
	end
	println(statName)
	for so in stats
		if contains(lowercase(statName), "bias")
			@printf("%s\t%.0fs\n", so.name, so.sdict[statName])
		else
			@printf("%s\t%.2f%%\n", so.name, so.sdict[statName])
		end
	end
end

"""
	`plotStats`: plot stat evolution from list of NetworkStats objects
"""
function plotStats(stats::Vector{NetworkStats}, statName::AbstractString)
	# check if stat is valid and if timebounds are same
	for so in stats
		if !(statName in collect(keys(so.sdict)))
			error("Statistic not found")
		end
	end
	x = collect(eachindex(stats))
	xlabels = [so.name for so in stats]
	plot(x, [so.sdict[statName] for so in stats], "o", color = "red")
	end
	xticks(x, xlabels)
	xlabel("Method used")
	ylabel(statName)
	title("$(statName)")
	margins(0.2)
end
