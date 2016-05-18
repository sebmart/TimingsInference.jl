###################################################
## geo/statistics.jl
## define methods to calculate errors on GeoTrips using DataSplits
###################################################

"""
	`tripsLogError`: compute log error on passed set of indices
"""
function tripsLogError(gt::GeoTimings, IDlist::Vector{Int})
	error = 0.
	counter = 0
	for ID in IDlist
		timing = estimateTime(gt, ID)
		error += abs(log(timing/gt.trips[ID].time))
		counter += 1
	end
	error = error/counter
	return error
end
trTripsLogError(gt::GeoTimings, ds::DataSplit) = tripsLogError(gt, trainSet(ds))
testTripsLogError(gt::GeoTimings, ds::DataSplit) = tripsLogError(gt, testSet(ds))

"""
	`tripsLogBias`: compute log bias on trips for whatever set of indices is passed
	Log bias is defined as (log predicted time - log real time)
"""
function tripsLogBias(gt::GeoTimings, IDlist::Vector{Int})
	bias = 0.
	for ID in IDlist
		timing = estimateTime(gt, ID)
		bias += log(timing) - log(gt.trips[ID].time)
	end
	bias = bias / length(IDlist)
	return bias
end
testTripsLogBias(gt::GeoTimings, ds::DataSplit) = tripsLogBias(gt, testSet(ds))
trTripsLogBias(gt::GeoTimings, ds::DataSplit) = tripsLogBias(gt, trainSet(ds))

"""
	`tripsLogErrorByTime`: returns RMS on indicated subset of GeoData, subsetting errors in different time buckets
"""
function tripsLogErrorByTime(gt::GeoTimings, IDlist::Vector{Int}, timeBound::Array{Float64,1} = [270., 450., 720., 900., 100_000.])
	numBins = length(timeBound)
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	for ID in IDlist
		idx = 1
		timing = estimateTime(gt, ID)
		while timing > timeBound[idx]
			idx += 1
		end
		error[idx] += abs(log(timing/gt.trips[ID].time))
		numInBin[idx] += 1
	end
	error = error ./ numInBin
	return error
end
trTripsLogErrorByTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogErrorByTime(gt, trainSet(ds), timeBound)
testTripsLogErrorByTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogErrorByTime(gt, testSet(ds), timeBound)

"""
	`tripsLogBiasByTime`: returns log bias on indicated subset of GeoData, subsetting errors in different time buckets
"""
function tripsLogBiasByTime(gt::GeoTimings, IDlist::Vector{Int}, timeBound::Array{Float64,1} = [270.,450., 720., 900., 100_000.])
	numBins = length(timeBound)
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	for ID in IDlist
		idx = 1
		timing = estimateTime(gt, ID)
		while timing > timeBound[idx]
			idx += 1
		end
		error[idx] += (log(timing) - log(gt.trips[ID].time))
		numInBin[idx] += 1
	end
	error = error ./ numInBin
	return error
end
trTripsLogBiasByTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogBiasByTime(gt, trainSet(ds), timeBound)
testTripsLogBiasByTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogBiasByTime(gt, testSet(ds), timeBound)
