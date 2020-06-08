###################################################
## geo/stats/stats.jl
## Data type to save geotrip stats
###################################################

"""
`GeoStats` : abstract type that stores statistics about an algorithm run
must implement attributes:
- `name` : some information about the method used to generate this
- `sdict` : dictionary mapping stat names to relevant values
must implement methods:
- `printStats` : print a summary of statistics on the algorithm run
"""

abstract type GeoStats end
function Base.show(io::IO, so::GeoStats)
	typeName = split(string(typeof(so)),".")[end]
	println(io, "$(typeName): $(so.name)")
end

"""
	`RealGeoStats`: instance of GeoStats, made for real trip data
"""
mutable struct RealGeoStats <: GeoStats
	name::AbstractString
	sdict::Dict{AbstractString, Union{Float64, Array{Float64,1}}}

	"array containing upper bounds for time breakdown of stats"
	timeBound::Array{Float64,1}
	function RealGeoStats(name::AbstractString, gt::GeoTimings, ds::DataSplit,
		timeBound::Vector{Float64} = [270., 450., 720., 900., 100_000.])
		obj = new()
		obj.name = name
		obj.timeBound = timeBound
		times = Float64[estimateTime(gt, ID) for ID in eachindex(gt.trips)]
		obj.sdict = Dict{AbstractString, Union{Float64, Array{Float64,1}}}(
			"testTripsLogError" => testTripsLogError(gt, ds, times),
			"trTripsLogError" => trTripsLogError(gt, ds, times),
			"testTripsLogBias" => testTripsLogBias(gt, ds, times),
			"trTripsLogBias" => trTripsLogBias(gt, ds, times),
			# "testTripsLogErrorbt" => 100 * testTripsLogErrorByTime(gt, ds, times, obj.timeBound),
			# "trTripsLogErrorbt" => 100 * trTripsLogErrorByTime(gt, ds, times, obj.timeBound),
			# "testTripsLogBiasbt" => 100 * testTripsLogBiasByTime(gt, ds, times, obj.timeBound),
			# "trTripsLogBiasbt" => 100 * trTripsLogBiasByTime(gt, ds, times, obj.timeBound)
		)
		return obj
	end
end

"""
	`printStats`: prints out all statistics identified by statName stored in given GeoStats
	Optional argument outputFileName if you want to write this to a file instead
"""
function printStats(so::RealGeoStats; outputFileName = "")
	if outputFileName == ""
		println(so)
		for statName in sort(collect(keys(so.sdict)))
			if occursin("bt", statName)
				println(statName, ":")
				for (i,time) in enumerate(so.timeBound)
					if occursin("bias", lowercase(statName)) && !occursin("log", lowercase(statName))
						@printf("\t\tTime < %.0f s:\t%.0fs\n", time, so.sdict[statName][i])
					else
						@printf("\t\tTime < %.0f s:\t%.5f\n", time, so.sdict[statName][i])
					end
				end
			elseif occursin("bias", lowercase(statName)) && !occursin("log", lowercase(statName))
				print(statName, ":\t")
				@printf("%.2f s\n", so.sdict[statName])
			else
				print(statName, ":\t")
				@printf("%.5f\n", so.sdict[statName])
			end
		end
	else
		f = open(outputFileName, "w")
		write(f, so)
		for statName in sort(collect(keys(so.sdict)))
			if occursin("bt", statName)
				for (i,time) in enumerate(so.timeBound)
					if occursin("bias", lowercase(statName)) && !occursin("log", lowercase(statName))
						@printf(f, "\t\tTime < %.0f s:\t%.0fs\n", time, so.sdict[statName][i])
					else
						@printf(f, "\t\tTime < %.0f s:\t%.5f\n", time, so.sdict[statName][i])
					end
				end
			elseif occursin("bias", lowercase(statName)) && !occursin("log", lowercase(statName))
				write(f, string(statName, ":\t"))
				@printf(f, "%.0fs\n", so.sdict[statName])
			else
				write(f, string(statName, ":\t"))
				@printf(f, "%.5f\n", so.sdict[statName])
			end
		end
		close(f)
	end
end

"""
	`printStats`: print relevant statistics, identified by statName, stored in given GeoStats object
"""
function printStats(stats::Vector{RealGeoStats}, statName::AbstractString)
	# check if stat is valid and if timebounds are same
	for so in stats
		if !(statName in collect(keys(so.sdict)))
			error("Statistic not found")
		end
		if occursin("bt", statName)
			if so.timeBound != stats[1].timeBound
				error("Time breakdown arrays don't match")
			end
		end
	end
	# set up top row
	println(statName)
	if occursin("bt", statName)
		print("\t\t")
		for time in stats[1].timeBound
			@printf("< %.0fs\t", time)
		end
		print("\n")
	end
	for so in stats
		if occursin("bt", statName)
			print(so.name, "\t")
			for (i,time) in enumerate(so.timeBound)
				if occursin("bias", lowercase(statName)) && !occursin("log", lowercase(statName))
					@printf("%.0fs\t", so.sdict[statName][i])
				else
					@printf("%.5f\t", so.sdict[statName][i])
				end
			end
			print("\n")
		elseif occursin("bias", lowercase(statName)) && !occursin("log", lowercase(statName))
			@printf("%s\t\t%.0fs\n", so.name, so.sdict[statName])
		else
			@printf("%s\t\t%.5f\n", so.name, so.sdict[statName])
		end
	end
end

"""
	`plotStats`: plot relevant statistic, identified by statName, stored in given GeoStats object
"""
function plotStats(stats::Vector{RealGeoStats}, statName::AbstractString; color::AbstractString="red")
	COLORS = ["red", "blue", "green", "orange", "black"]
	LABELS = ["<4min30s", "<7min30s", "<12min", "<15min", ">15 min"]
	# check if stat is valid and if timebounds are same
	for so in stats
		if !(statName in collect(keys(so.sdict)))
			error("Statistic not found")
		end
		if occursin("bt", statName)
			if so.timeBound != stats[1].timeBound
				error("Time breakdown arrays don't match")
			end
		end
	end
	x = collect(eachindex(stats))
	xlabels = [so.name for so in stats]
	if occursin("bt", statName)
		for (i, timeBound) in enumerate(stats[1].timeBound)
			stat = [stats[j].sdict[statName][i] for j=eachindex(stats)]
			plot(x, stat, "o", color = COLORS[i % 5 + 1], label = LABELS[i])
		end
		legend(loc="best")
	else
		plot(x, [so.sdict[statName] for so in stats], "o", color = color)
	end
	xticks(x, xlabels, rotation = "vertical")
	xlabel("Method used")
	ylabel(statName)
	title("$(statName)")
	margins(0.2)
end
