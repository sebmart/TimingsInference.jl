###################################################
## splitdata.jl
## split data into training/testing subsets
###################################################

"""
	`DataSplit`: abstract type with information about how the dataset is split into training and testing sets
	must implement attributes:
	- trainingIDs: list of IDs of trips of training set
	- testingIDs: list of IDs of trips of testing set
	- geodata: GeoData object that this DataSplit object is related to
"""
abstract DataSplit

function Base.show(io::IO, ds::DataSplit)
	typeName = split(string(typeof(ds)),".")[end]
	println(io, "DataSplit: $(typeName)")
end

"""
	`RandomSplit`: split data set randomly, with a given fraction of the data in the training set
	and the remainder in the testing set
"""
type RandomSplit <: DataSplit
	# compulsory
	trainingIDs::Vector{Int}
	testingIDs::Vector{Int}
	geodata::GeoData

	# particular
	fractionTrain::Float64
	function RandomSplit(geodata::GeoData, fractionTrain::Float64, trips::AbstractArray{Int64, 1} = eachindex(geodata))
		obj = new()
		obj.geodata = geodata
		obj.fractionTrain = fractionTrain
		# split set of trips into training and testing
		shuf = shuffle(collect(trips))
		endTraining = round(Int, fractionTrain * length(trips))
		obj.trainingIDs = sort(shuf[1:endTraining])
		obj.testingIDs = sort(shuf[(endTraining + 1):end])
		return obj
	end
end

"""
    `NetworkData` : convenience function to create NetworkData using Projector and DataSplit
"""
function NetworkData(
	proj::NetworkProjector,
	datasplit::DataSplit,
    minTimes::AbstractArray{Float64,2} = maxSpeedTimes(proj.network); #max speeds timings
    args...)
    # Create the "NetworkTrip" array
    return NetworkData(proj.network, getNetworkTrips(proj, datasplit.trainingIDs, args...), minTimes)
end

########### STATISTICS ###########
"""
	`tripsMAE`: compute MAE on whatever set of indices is passed
"""
function tripsMAE(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, IDlist::Vector{Int})
	tt = getPathTimes(timings)
	error = 0.
	counter = 0
	for ID in IDlist
		timing = getTripTiming(proj, timings, ID)
		if timing != NaN
			error += abs(timing - ds.geodata[ID].time)/ds.geodata[ID].time
			counter += 1
		end
	end
	error = error / counter
	return error
end

"""
	`testTripsMAE`: compute MAE on testing set 
"""
testTripsMAE(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsMAE(timings, proj, ds, ds.testingIDs)

"""
	`trTripsMAE`: compute MAE on training set
"""
trTripsMAE(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsMAE(timings, proj, ds, ds.trainingIDs)

"""
	`tripsRMS`: compute RMS on whatever set of indices is passed
"""
function tripsRMS(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, IDlist::Vector{Int})
	tt = getPathTimes(timings)
	error = 0.
	counter = 0
	for ID in IDlist
		timing = getTripTiming(proj, timings, ID)
		if timing != NaN
			error += ((timing - ds.geodata[ID].time)/ds.geodata[ID].time)^2
			counter += 1
		end
	end
	error = sqrt(error/counter)
	return error
end

"""
	`testTripsRMS`: compute RMS on testing set 
"""
testTripsRMS(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsRMS(timings, proj, ds, ds.testingIDs)

"""
	`trTripsRMS`: compute RMS on training set
"""
trTripsRMS(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsRMS(timings, proj, ds, ds.trainingIDs)

"""
	`tripsBias`: compute bias on trips for whatever set of indices is passed
	Bias is defined as (predicted time - real time)
"""
function tripsBias(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, IDlist::Vector{Int})
	tt = getPathTimes(timings)
	bias = 0.
	counter = 0
	for ID in IDlist
		timing = getTripTiming(proj, timings, ID)
		if timing != NaN
			bias += (timing - ds.geodata[ID].time)
			counter += 1
		end
	end
	bias = bias / length(IDlist)
	return bias
end

"""
	`testTripsBias`: compute Bias on testing set 
"""
testTripsBias(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsBias(timings, proj, ds, ds.testingIDs)

"""
	`trTripsBias`: compute Bias on training set
"""
trTripsBias(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsBias(timings, proj, ds, ds.trainingIDs)

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
function tripsMAEbyTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, IDlist::Vector{Int}, timeBound::Array{Float64,1} = [0.15, 0.25, 0.40, 0.50, 1.])
	maxTime = maximum([ds.geodata[id].time for id in IDlist])
	numBins = length(timeBound)
	timeBound = maxTime * timeBound
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	for ID in IDlist
		idx = 1
		while ds.geodata[ID].time > timeBound[idx]
			idx += 1
		end
		timing = getTripTiming(proj, timings, ID)
		if timing != NaN
			error[idx] += abs(timing - ds.geodata[ID].time)/ds.geodata[ID].time
			numInBin[idx] += 1
		end
	end
	error = error ./ numInBin
	return error
end

trTripsMAEbyTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 1.]) = tripsMAEbyTime(timings, proj, ds, ds.trainingIDs, timeBound)

testTripsMAEbyTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 1.]) = tripsMAEbyTime(timings, proj, ds, ds.testingIDs, timeBound)

"""
	`tripsRMSbyTime`: returns RMS on indicated subset of GeoData, subsetting errors in different time buckets
"""
function tripsRMSbyTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, IDlist::Vector{Int}, timeBound::Array{Float64,1} = [0.15, 0.25, 0.40, 0.50, 1.])
	maxTime = maximum([ds.geodata[id].time for id in IDlist])
	numBins = length(timeBound)
	timeBound = maxTime * timeBound
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	for ID in IDlist
		idx = 1
		while ds.geodata[ID].time > timeBound[idx]
			idx += 1
		end
		timing = getTripTiming(proj, timings, ID)
		if timing != NaN
			error[idx] += ((timing - ds.geodata[ID].time)/ds.geodata[ID].time)^2
			numInBin[idx] += 1
		end
	end
	error = sqrt(error ./ numInBin)
	return error
end

trTripsRMSbyTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 1.]) = tripsRMSbyTime(timings, proj, ds, ds.trainingIDs, timeBound)

testTripsRMSbyTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 1.]) = tripsRMSbyTime(timings, proj, ds, ds.testingIDs, timeBound)

"""
	`tripsBiasByTime`: returns bias on indicated subset of GeoData, subsetting errors in different time buckets
"""
function tripsBiasByTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, IDlist::Vector{Int}, timeBound::Array{Float64,1} = [0.15, 0.25, 0.40, 0.50, 1.])
	maxTime = maximum([ds.geodata[id].time for id in IDlist])
	numBins = length(timeBound)
	timeBound = maxTime * timeBound
	error = 0. * collect(1:numBins)
	numInBin = 0 * collect(1:numBins)
	for ID in IDlist
		idx = 1
		while ds.geodata[ID].time > timeBound[idx]
			idx += 1
		end
		timing = getTripTiming(proj, timings, ID)
		if timing != NaN
			error[idx] += (timing - ds.geodata[ID].time)
			numInBin[idx] += 1
		end
	end
	error = error ./ numInBin
	return error
end

trTripsBiasByTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 1.]) = tripsBiasByTime(timings, proj, ds, ds.trainingIDs, timeBound)

testTripsBiasByTime(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, timeBound::Array{Float64, 1} = [0.15, 0.25, 0.40, 0.50, 1.]) = tripsBiasByTime(timings, proj, ds, ds.testingIDs, timeBound)