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
		endTraining = round(fractionTrain * length(trips), Int)
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

"""
	`tripsMAE`: compute MAE on whatever set of indices is passed
"""
function tripsMAE(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit, IDlist::Vector{Int})
	tt = getPathTimes(timings)
	error = 0.
	for ID in IDlist
		error += (getTripTiming(proj, timings, ID) - ds.geodata[ID].time)/ds.geodata[ID].time
	end
	error = error / length(IDlist)
	return error
end

"""
	`testingTripsMAE`: compute MAE on testing set 
"""
testingTripsMAE(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsMAE(timings, proj, ds, ds.testingIDs)

"""
	`trainingTripsMAE`: compute MAE on full training set
"""
trainingTripsMAE(timings::NetworkTimings, proj::NetworkProjector, ds::DataSplit) = tripsMAE(timings, proj, ds, ds.trainingIDs)