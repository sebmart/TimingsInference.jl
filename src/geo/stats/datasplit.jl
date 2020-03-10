###################################################
## geo/stats/datasplit.jl
## split data into training/testing subsets
###################################################

"""
	`DataSplit`: abstract type with information about how the dataset is split into training and testing sets
	must implement attributes:
	- trainingIDs: list of IDs of trips of training set
	- testingIDs: list of IDs of trips of testing set
	- geodata: GeoData object that this DataSplit object is related to
"""
abstract type DataSplit end

function Base.show(io::IO, ds::DataSplit)
	typeName = split(string(typeof(ds)),".")[end]
	println(io, "DataSplit: $(typeName)")
end

trainSet(s::DataSplit) = s.trainingIDs
testSet(s::DataSplit) = s.testingIDs

"""
	`RandomSplit`: split data set randomly, with a given fraction of the data in the training set
	and the remainder in the testing set
"""
mutable struct RandomSplit <: DataSplit
	# compulsory
	trainingIDs::Vector{Int}
	testingIDs::Vector{Int}
	geodata::GeoData

	# particular
	fractionTrain::Float64
	function RandomSplit(geodata::GeoData, fractionTrain::Float64, trips::AbstractArray{Int, 1} = eachindex(geodata))
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
	`LocSplit`: split data set geographically. All testing rides are included in a 4D sphere, everything else forms training set.
"""
mutable struct LocSplit <: DataSplit
	# compulsory
	trainingIDs::Vector{Int}
	testingIDs::Vector{Int}
	geodata::GeoData

	"graph with which this is identified"
	network::Network
	"center of 4D sphere containing testing set"
	center::Tuple{Float64, Float64, Float64, Float64}
	"radius of 4D sphere containing testing set"
	radius::Float64
	function LocSplit(geodata::GeoData, network::Network, center::Tuple{Float64, Float64, Float64, Float64}, radius::Float64, trips::AbstractArray{Int,1} = eachindex(geodata))
		obj = new()
		obj.geodata = geodata
		obj.center = center
		obj.radius = radius
		obj.network = network
		mask = BitArray(length(trips))
		for i in trips
			pX, pY = toENU(geodata[i].pLon, geodata[i].pLat, network)
			dX, dY = toENU(geodata[i].dLon, geodata[i].dLat, network)
			mask[i] = ( (center[1] - pX)^2 + (center[2] - pY)^2 + (center[3] - dX)^2 + (center[4] - dY)^2 < radius^2 )
		end
		obj.trainingIDs = trips[!mask]
		obj.testingIDs = trips[mask]
		return obj
	end
end

# extra classes for center/radius given as Int
LocSplit(geodata::GeoData, network::Network, center::Tuple{Int, Int, Int, Int}, radius::Float64, trips::AbstractArray{Int,1} = eachindex(geodata)) = LocSplit(geodata, network, (Float64(center[1]), Float64(center[2]), Float64(center[3]), Float64(center[4])), radius, trips)
LocSplit(geodata::GeoData, network::Network, center::Tuple{Int, Int, Int, Int}, radius::Int, trips::AbstractArray{Int,1} = eachindex(geodata)) = LocSplit(geodata, network, (Float64(center[1]), Float64(center[2]), Float64(center[3]), Float64(center[4])), Float64(radius), trips)
LocSplit(geodata::GeoData, network::Network, center::Tuple{Float64, Float64, Float64, Float64}, radius::Int, trips::AbstractArray{Int,1} = eachindex(geodata)) = LocSplit(geodata, network, center, Float64(radius), trips)