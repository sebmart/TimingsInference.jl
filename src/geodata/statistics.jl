###################################################
## geodata/statistics.jl
## statistics with real data
###################################################

"""
	`tripsMAE`: compute MAE on whatever set of indices is passed
"""
function tripsMAE(timings::NetworkTimings, proj::NetworkProjector, IDlist::Vector{Int})
	tt = getPathTimes(timings)
	error = 0.
	counter = 0
	for ID in IDlist
		timing = getTripTiming(proj, timings, ID)
		if !isnan(timing)
			error += abs(timing - proj.trips[ID].time)/proj.trips[ID].time
			counter += 1
		end
	end
	error = error / counter
	return error
end

"""
	`testTripsMAE`: compute MAE on testing set
"""
testTripsMAE(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsMAE(timings, proj, ds.testingIDs)

"""
	`trTripsMAE`: compute MAE on training set
"""
trTripsMAE(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsMAE(timings, proj, ds.trainingIDs)

"""
	`tripsRMS`: compute RMS on whatever set of indices is passed
"""
function tripsRMS(timings::NetworkTimings, proj::NetworkProjector, IDlist::Vector{Int})
	tt = getPathTimes(timings)
	error = 0.
	counter = 0
	for ID in IDlist
		timing = getTripTiming(proj, timings, ID)
		if !isnan(timing)
			error += ((timing - proj.trips[ID].time)/proj.trips[ID].time)^2
			counter += 1
		end
	end
	error = sqrt(error/counter)
	return error
end

"""
	`testTripsRMS`: compute RMS on testing set
"""
testTripsRMS(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsRMS(timings, proj, ds.testingIDs)

"""
	`trTripsRMS`: compute RMS on training set
"""
trTripsRMS(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsRMS(timings, proj, ds.trainingIDs)

"""
	`tripsBias`: compute bias on trips for whatever set of indices is passed
	Bias is defined as (predicted time - real time)
"""
function tripsBias(timings::NetworkTimings, proj::NetworkProjector, IDlist::Vector{Int})
	tt = getPathTimes(timings)
	bias = 0.
	counter = 0
	for ID in IDlist
		timing = getTripTiming(proj, timings, ID)
		if !isnan(timing)
			bias += (timing - proj.trips[ID].time)
			counter += 1
		end
	end
	bias = bias / length(IDlist)
	return bias
end

"""
	`testTripsBias`: compute Bias on testing set
"""
testTripsBias(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsBias(timings, proj, ds.testingIDs)

"""
	`trTripsBias`: compute Bias on training set
"""
trTripsBias(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsBias(timings, proj, ds.trainingIDs)

"""
	`networkTripsMAE`: convert GeoTrips to NetworkTrips and compute their MAE
"""
networkTripsMAE(timings::NetworkTimings, proj::NetworkProjector, IDlist::Vector{Int}) = tripsMAE(timings, getNetworkTrips(proj, IDlist))
trNetworkTripsMAE(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = networkTripsMAE(timings, proj, ds.trainingIDs)
testNetworkTripsMAE(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = networkTripsMAE(timings, proj, ds.testingIDs)

"""
	`networkTripsRMS`: convert GeoTrips to NetworkTrips and compute their RMS
"""
networkTripsRMS(timings::NetworkTimings, proj::NetworkProjector, IDlist::Vector{Int}) = tripsRMS(timings, getNetworkTrips(proj, IDlist))
trNetworkTripsRMS(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = networkTripsRMS(timings, proj, ds.trainingIDs)
testNetworkTripsRMS(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = networkTripsRMS(timings, proj, ds.testingIDs)

"""
	`networkTripsRMS`: convert GeoTrips to NetworkTrips and compute their RMS
"""
networkTripsBias(timings::NetworkTimings, proj::NetworkProjector, IDlist::Vector{Int}) = tripsBias(timings, getNetworkTrips(proj, IDlist))
trNetworkTripsBias(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = networkTripsBias(timings, proj, ds.trainingIDs)
testNetworkTripsBias(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = networkTripsBias(timings, proj, ds.testingIDs)

"""
	`tripsMAEbyTime`: returns MAE on indicated subset of GeoData, subsetting errors in different time buckets
"""
function tripsMAEbyTime(timings::NetworkTimings, proj::NetworkProjector, IDlist::Vector{Int}, timeBound::Array{Float64,1} = [0.15, 0.25, 0.40, 0.50, 100.])
	maxTime = 1800.
	numBins = length(timeBound)
	timeBound = maxTime * timeBound
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	for ID in IDlist
		idx = 1
		while proj.trips[ID].time > timeBound[idx]
			idx += 1
		end
		timing = getTripTiming(proj, timings, ID)
		if !isnan(timing)
			error[idx] += abs(timing - proj.trips[ID].time)/proj.trips[ID].time
			numInBin[idx] += 1
		end
	end
	error = error ./ numInBin
	return error
end

trTripsMAEbyTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 100.]) = tripsMAEbyTime(timings, proj, ds.trainingIDs, timeBound)

testTripsMAEbyTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 100.]) = tripsMAEbyTime(timings, proj, ds.testingIDs, timeBound)

"""
	`tripsRMSbyTime`: returns RMS on indicated subset of GeoData, subsetting errors in different time buckets
"""
function tripsRMSbyTime(timings::NetworkTimings, proj::NetworkProjector, IDlist::Vector{Int}, timeBound::Array{Float64,1} = [0.15, 0.25, 0.40, 0.50, 100.])
	maxTime = 1800.
	numBins = length(timeBound)
	timeBound = maxTime * timeBound
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	for ID in IDlist
		idx = 1
		while proj.trips[ID].time > timeBound[idx]
			idx += 1
		end
		timing = getTripTiming(proj, timings, ID)
		if !isnan(timing)
			error[idx] += ((timing - proj.trips[ID].time)/proj.trips[ID].time)^2
			numInBin[idx] += 1
		end
	end
	error = sqrt(error ./ numInBin)
	return error
end

trTripsRMSbyTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 100.]) = tripsRMSbyTime(timings, proj, ds.trainingIDs, timeBound)

testTripsRMSbyTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 100.]) = tripsRMSbyTime(timings, proj, ds.testingIDs, timeBound)

"""
	`tripsBiasByTime`: returns bias on indicated subset of GeoData, subsetting errors in different time buckets
"""
function tripsBiasByTime(timings::NetworkTimings, proj::NetworkProjector, IDlist::Vector{Int}, timeBound::Array{Float64,1} = [0.15, 0.25, 0.40, 0.50, 100.])
	maxTime = 1800.
	numBins = length(timeBound)
	timeBound = maxTime * timeBound
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	for ID in IDlist
		idx = 1
		while proj.trips[ID].time > timeBound[idx]
			idx += 1
		end
		timing = getTripTiming(proj, timings, ID)
		if !isnan(timing)
			error[idx] += (timing - proj.trips[ID].time)
			numInBin[idx] += 1
		end
	end
	error = error ./ numInBin
	return error
end

trTripsBiasByTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 100.]) = tripsBiasByTime(timings, proj, ds.trainingIDs, timeBound)

testTripsBiasByTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 100.]) = tripsBiasByTime(timings, proj, ds.testingIDs, timeBound)
