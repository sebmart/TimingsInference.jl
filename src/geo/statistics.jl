###################################################
## geo/statistics.jl
## define methods to calculate errors on GeoTrips using DataSplits
###################################################

"""
	`tripsMAE`: compute MAE on whatever set of indices is passed
"""
function tripsMAE(gt::GeoTimings, IDlist::Vector{Int})
	error = 0.
	counter = 0
	for ID in IDlist
		timing = estimateTime(gt, ID)
		if !isnan(timing)
			error += abs(timing - gt.trips[ID].time)/gt.trips[ID].time
			counter += 1
		end
	end
	error = error / counter
	return error
end

"""
	`testTripsMAE`: compute MAE on testing set
"""
testTripsMAE(gt::GeoTimings, ds::DataSplit) = tripsMAE(gt, testSet(ds))

"""
	`trTripsMAE`: compute MAE on training set
"""
trTripsMAE(gt::GeoTimings, ds::DataSplit) = tripsMAE(gt, trainSet(ds))

"""
	`tripsLogError`: compute log error on passed set of indices
"""
function tripsLogError(gt::GeoTimings, IDlist::Vector{Int})
	error = 0.
	counter = 0
	for ID in IDlist
		timing = estimateTime(gt, ID)
		if !isnan(timing)
			error += abs(log(timing/gt.trips[ID].time))
			counter += 1
		end
	end
	error = error/counter
	return error
end
trTripsLogError(gt::GeoTimings, ds::DataSplit) = tripsLogError(gt, trainSet(ds))
testTripsLogError(gt::GeoTimings, ds::DataSplit) = tripsLogError(gt, testSet(ds))

"""
	`tripsRMS`: compute RMS on whatever set of indices is passed
"""
function tripsRMS(gt::GeoTimings, IDlist::Vector{Int})
	error = 0.
	counter = 0
	for ID in IDlist
		timing = estimateTime(gt, ID)
		if !isnan(timing)
			error += ((timing - gt.trips[ID].time)/gt.trips[ID].time)^2
			counter += 1
		end
	end
	error = sqrt(error/counter)
	return error
end

"""
	`testTripsRMS`: compute RMS on testing set
"""
testTripsRMS(gt::GeoTimings, ds::DataSplit) = tripsRMS(gt, testSet(ds))

"""
	`trTripsRMS`: compute RMS on training set
"""
trTripsRMS(gt::GeoTimings, ds::DataSplit) = tripsRMS(gt, trainSet(ds))

"""
	`tripsBias`: compute bias on trips for whatever set of indices is passed
	Bias is defined as (predicted time - real time)
"""
function tripsBias(gt::GeoTimings, IDlist::Vector{Int})
	bias = 0.
	counter = 0
	for ID in IDlist
		timing = estimateTime(gt, ID)
		if !isnan(timing)
			bias += (timing - gt.trips[ID].time)
			counter += 1
		end
	end
	bias = bias / length(IDlist)
	return bias
end

"""
	`testTripsBias`: compute Bias on testing set
"""
testTripsBias(gt::GeoTimings, ds::DataSplit) = tripsBias(gt, testSet(ds))

"""
	`trTripsBias`: compute Bias on training set
"""
trTripsBias(gt::GeoTimings, ds::DataSplit) = tripsBias(gt, trainSet(ds))

"""
	`tripsLogBias`: compute log bias on trips for whatever set of indices is passed
	Log bias is defined as (log predicted time - log real time)
"""
function tripsLogBias(gt::GeoTimings, IDlist::Vector{Int})
	bias = 0.
	counter = 0
	for ID in IDlist
		timing = estimateTime(gt, ID)
		if !isnan(timing)
			bias += (log(timing) - log(gt.trips[ID].time))
			counter += 1
		end
	end
	bias = bias / length(IDlist)
	return bias
end

"""
	`testTripsLogBias`: compute Log Bias on testing set
"""
testTripsLogBias(gt::GeoTimings, ds::DataSplit) = tripsLogBias(gt, testSet(ds))

"""
	`trTripsLogBias`: compute Log Bias on training set
"""
trTripsLogBias(gt::GeoTimings, ds::DataSplit) = tripsLogBias(gt, trainSet(ds))

"""
	`tripsMAEbyTime`: returns MAE on indicated subset of GeoData, subsetting errors in different time buckets
"""
function tripsMAEbyTime(gt::GeoTimings, IDlist::Vector{Int}, timeBound::Array{Float64,1} = [270., 450., 720., 900., 100_000.])
	numBins = length(timeBound)
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	for ID in IDlist
		idx = 1
		timing = estimateTime(gt, ID)
		while timing > timeBound[idx]
			idx += 1
		end
		if !isnan(timing)
			error[idx] += abs(timing - gt.trips[ID].time)/gt.trips[ID].time
			numInBin[idx] += 1
		end
	end
	error = error ./ numInBin
	return error
end
trTripsMAEbyTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsMAEbyTime(gt, trainSet(ds), timeBound)
testTripsMAEbyTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsMAEbyTime(gt, testSet(ds), timeBound)

"""
	`tripsRMSbyTime`: returns RMS on indicated subset of GeoData, subsetting errors in different time buckets
"""
function tripsRMSbyTime(gt::GeoTimings, IDlist::Vector{Int}, timeBound::Array{Float64,1} = [270., 450., 720., 900., 100_000.])
	numBins = length(timeBound)
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	for ID in IDlist
		idx = 1
		timing = estimateTime(gt, ID)
		while timing > timeBound[idx]
			idx += 1
		end
		if !isnan(timing)
			error[idx] += ((timing - gt.trips[ID].time)/gt.trips[ID].time)^2
			numInBin[idx] += 1
		end
	end
	error = sqrt(error ./ numInBin)
	return error
end
trTripsRMSbyTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsRMSbyTime(gt, trainSet(ds), timeBound)
testTripsRMSbyTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsRMSbyTime(gt, testSet(ds), timeBound)

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
		if !isnan(timing)
			error[idx] += abs(log(timing/gt.trips[ID].time))
			numInBin[idx] += 1
		end
	end
	error = error ./ numInBin
	return error
end
trTripsLogErrorByTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogErrorByTime(gt, trainSet(ds), timeBound)
testTripsLogErrorByTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogErrorByTime(gt, testSet(ds), timeBound)

"""
	`tripsBiasByTime`: returns bias on indicated subset of GeoData, subsetting errors in different time buckets
"""
function tripsBiasByTime(gt::GeoTimings, IDlist::Vector{Int}, timeBound::Array{Float64,1} = [270.,450., 720., 900., 100_000.])
	numBins = length(timeBound)
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	for ID in IDlist
		idx = 1
		timing = estimateTime(gt, ID)
		while timing > timeBound[idx]
			idx += 1
		end
		if !isnan(timing)
			error[idx] += (timing - gt.trips[ID].time)
			numInBin[idx] += 1
		end
	end
	error = error ./ numInBin
	return error
end
trTripsBiasByTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsBiasByTime(gt, trainSet(ds), timeBound)
testTripsBiasByTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsBiasByTime(gt, testSet(ds), timeBound)

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
		if !isnan(timing)
			error[idx] += (log(timing) - log(gt.trips[ID].time))
			numInBin[idx] += 1
		end
	end
	error = error ./ numInBin
	return error
end
trTripsLogBiasByTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogBiasByTime(gt, trainSet(ds), timeBound)
testTripsLogBiasByTime(gt::GeoTimings, ds::DataSplit, timeBound::Array{Float64, 1} = [270., 450., 720., 900., 100_000.]) = tripsLogBiasByTime(gt, testSet(ds), timeBound)
