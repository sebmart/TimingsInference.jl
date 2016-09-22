###################################################
## geo/stats/statistics.jl
## define methods to calculate errors on GeoTrips using DataSplits
###################################################

"""
	`tripsLogError`: compute log error on passed set of indices
	Can pass in precomputed times for faster runtime
"""
function tripsLogError(gt::GeoTimings, IDlist::Vector{Int}, times::Vector{Float64}=Float64[])
	error = 0.
	counter = 0
	precomputed = (length(times) == length(gt.trips))
	for ID in IDlist
		if precomputed
			timing = times[ID]
		else
			timing = estimateTime(gt, ID)
		end
		if timing > 0.
			error += abs(log(timing/gt.trips[ID].time))
			counter += 1
		end
	end
	error = error/counter
	return error
end
trTripsLogError(gt::GeoTimings, ds::DataSplit, times::Vector{Float64}=Float64[]) = tripsLogError(gt, trainSet(ds), times)
testTripsLogError(gt::GeoTimings, ds::DataSplit, times::Vector{Float64}=Float64[]) = tripsLogError(gt, testSet(ds), times)

"""
	`tripsLogBias`: compute log bias on trips for whatever set of indices is passed
	Log bias is defined as (log predicted time - log real time)
	Can pass in precomputed times for faster runtime
"""
function tripsLogBias(gt::GeoTimings, IDlist::Vector{Int}, times::Vector{Float64}=Float64[])
	bias = 0.
	counter = 0
	precomputed = (length(times) == length(gt.trips))
	for ID in IDlist
		if precomputed
			timing = times[ID]
		else
			timing = estimateTime(gt, ID)
		end
		if timing > 0
			bias += log(timing) - log(gt.trips[ID].time)
			counter += 1
		end
	end
	bias = bias / counter
	return bias
end
testTripsLogBias(gt::GeoTimings, ds::DataSplit, times::Vector{Float64}=Float64[]) = tripsLogBias(gt, testSet(ds), times)
trTripsLogBias(gt::GeoTimings, ds::DataSplit, times::Vector{Float64}=Float64[]) = tripsLogBias(gt, trainSet(ds), times)

"""
	`tripsLogErrorByTime`: returns RMS on indicated subset of GeoData, subsetting errors in different time buckets
	Can pass in precomputed times for faster runtime
"""
function tripsLogErrorByTime(gt::GeoTimings, IDlist::Vector{Int}, times::Vector{Float64}=Float64[], timeBound::Array{Float64,1} = [270., 450., 720., 900., 100_000.])
	numBins = length(timeBound)
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	precomputed = (length(times) == length(gt.trips))
	for ID in IDlist
		idx = 1
		if precomputed
			timing = times[ID]
		else
			timing = estimateTime(gt, ID)
		end
		while timing > timeBound[idx] && idx < length(timeBound)
			idx += 1
		end
		if timing > 0
			error[idx] += abs(log(timing/gt.trips[ID].time))
			numInBin[idx] += 1
		end
	end
	error = error ./ numInBin
	return error
end
trTripsLogErrorByTime(gt::GeoTimings, ds::DataSplit, times::Vector{Float64}=Float64[], timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogErrorByTime(gt, trainSet(ds), times, timeBound)
testTripsLogErrorByTime(gt::GeoTimings, ds::DataSplit, times::Vector{Float64}=Float64[], timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogErrorByTime(gt, testSet(ds), times, timeBound)

"""
	`tripsLogBiasByTime`: returns log bias on indicated subset of GeoData, subsetting errors in different time buckets
	Can pass in precomputed times for faster runtime
"""
function tripsLogBiasByTime(gt::GeoTimings, IDlist::Vector{Int}, times::Vector{Float64}=Float64[], timeBound::Array{Float64,1} = [270.,450., 720., 900., 100_000.])
	numBins = length(timeBound)
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	precomputed = (length(times) == length(gt.trips))
	for ID in IDlist
		idx = 1
		if precomputed
			timing = times[ID]
		else
			timing = estimateTime(gt, ID)
		end
		while timing > timeBound[idx] && idx < length(timeBound)
			idx += 1
		end
		if timing > 0
			error[idx] += (log(timing) - log(gt.trips[ID].time))
			numInBin[idx] += 1
		end
	end
	error = error ./ numInBin
	return error
end
trTripsLogBiasByTime(gt::GeoTimings, ds::DataSplit, times::Vector{Float64}=Float64[], timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogBiasByTime(gt, trainSet(ds), times, timeBound)
testTripsLogBiasByTime(gt::GeoTimings, ds::DataSplit, times::Vector{Float64}=Float64[], timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogBiasByTime(gt, testSet(ds), times, timeBound)
