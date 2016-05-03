###################################################
## geo/stats.jl
## Data type to save geotrip stats
###################################################

"""
`GeoStats` : abstract type that stores statistics about an algorithm run
must implement attributes:
- name : some information about the method used to generate this
- sdict : dictionary mapping stat names to relevant values
must implement methods:
- printStats : print a summary of statistics on the algorithm run
"""

abstract GeoStats
function Base.show(io::IO, so::GeoStats)
	typeName = split(string(typeof(so)),".")[end]
	println(io, "$(typeName): $(so.name)")
end

"""
	`RealGeoStats`: instance of GeoStats, made for real trip data
"""
type RealGeoStats <: GeoStats
	name::AbstractString
	sdict::Dict{AbstractString, Union{Float64, Array{Float64,1}}}

	"array containing upper bounds for time breakdown of stats"
	timeBound::Array{Float64,1}
	function RealGeoStats(name::AbstractString, gt::GeoTimings, ds::DataSplit, 
		timeBound::Vector{Float64} = [270., 450., 720., 900., 100_000.])
		obj = new()
		obj.name = name
		obj.timeBound = timeBound
		obj.sdict = Dict{AbstractString, Union{Float64, Array{Float64,1}}}(
			"testTripsMAE" => 100 * testTripsMAE(gt, ds),
			"trTripsMAE" => 100 * trTripsMAE(gt, ds),
			"testTripsLogError" => 100 * testTripsLogError(gt, ds),
			"trTripsLogError" => 100 * trTripsLogError(gt, ds),
			"testTripsBias" => testTripsBias(gt, ds),
			"trTripsBias" => trTripsBias(gt, ds),
			"testTripsMAEbt" => 100 * testTripsMAEbyTime(gt, ds, obj.timeBound),
			"trTripsMAEbt" => 100 * trTripsMAEbyTime(gt, ds, obj.timeBound),
			"testTripsLogErrorbt" => 100 * testTripsLogErrorByTime(gt, ds, obj.timeBound),
			"trTripsLogErrorbt" => 100 * trTripsLogErrorByTime(gt, ds, obj.timeBound),
			"testTripsBiasbt" => testTripsBiasByTime(gt, ds, obj.timeBound),
			"trTripsBiasbt" => trTripsBiasByTime(gt, ds, obj.timeBound))
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
			if contains(statName, "bt")
				println(statName, ":")
				for (i,time) in enumerate(so.timeBound)
					if contains(lowercase(statName), "bias")
						@printf("\t\tTime < %.0f s:\t%.0fs\n", time, so.sdict[statName][i])
					else
						@printf("\t\tTime < %.0f s:\t%.2f%%\n", time, so.sdict[statName][i])
					end
				end
			elseif contains(lowercase(statName), "bias")
				print(statName, ":\t")
				@printf("%.2f s\n", so.sdict[statName])
			else
				print(statName, ":\t")
				@printf("%.2f%%\n", so.sdict[statName])
			end
		end
	else
		f = open(outputFileName, "w")
		write(f, so)
		for statName in sort(collect(keys(so.sdict)))
			if contains(statName, "bt")
				for (i,time) in enumerate(so.timeBound)
					if contains(lowercase(statName), "bias")
						@printf(f, "\t\tTime < %.0f s:\t%.0fs\n", time, so.sdict[statName][i])
					else
						@printf(f, "\t\tTime < %.0f s:\t%.2f%%\n", time, so.sdict[statName][i])
					end
				end
			elseif contains(lowercase(statName), "bias")
				write(f, string(statName, ":\t"))
				@printf(f, "%.0fs\n", so.sdict[statName])
			else
				write(f, string(statName, ":\t"))
				@printf(f, "%.2f%%\n", so.sdict[statName])
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
		if contains(statName, "bt")
			if so.timeBound != stats[1].timeBound
				error("Time breakdown arrays don't match")
			end
		end
	end
	# set up top row
	println(statName)
	if contains(statName, "bt")
		print("\t\t")
		for time in stats[1].timeBound
			@printf("< %.0fs\t", time)
		end
		print("\n")
	end
	for so in stats
		if contains(statName, "bt")
			print(so.name, "\t")
			for (i,time) in enumerate(so.timeBound)
				if contains(lowercase(statName), "bias")
					@printf("%.0fs\t", so.sdict[statName][i])
				else
					@printf("%.2f%%\t", so.sdict[statName][i])
				end
			end
			print("\n")
		elseif contains(lowercase(statName), "bias")
			@printf("%s\t\t%.0fs\n", so.name, so.sdict[statName])
		else
			@printf("%s\t\t%.2f%%\n", so.name, so.sdict[statName])
		end
	end
end

"""
	`plotStats`: plot relevant statistic, identified by statName, stored in given GeoStats object
"""
function plotStats(stats::Vector{RealGeoStats}, statName::AbstractString)
	COLORS = ["red", "blue", "green", "orange", "black"]
	LABELS = ["<4min30s", "<7min30s", "<12min", "<15min", ">15 min"]
	# check if stat is valid and if timebounds are same
	for so in stats
		if !(statName in collect(keys(so.sdict)))
			error("Statistic not found")
		end
		if contains(statName, "bt")
			if so.timeBound != stats[1].timeBound
				error("Time breakdown arrays don't match")
			end
		end
	end
	x = collect(eachindex(stats))
	xlabels = [so.name for so in stats]
	if contains(statName, "bt")
		for (i, timeBound) in enumerate(stats[1].timeBound)
			stat = [stats[j].sdict[statName][i] for j=eachindex(stats)]
			plot(x, stat, "o", color = COLORS[i % 5 + 1], label = LABELS[i])
		end
		legend(loc="best")
	else
		plot(x, [so.sdict[statName] for so in stats], "o", color = "red")
	end
	xticks(x, xlabels)
	xlabel("Method used")
	ylabel(statName)
	title("$(statName)")
	margins(0.2)
end
