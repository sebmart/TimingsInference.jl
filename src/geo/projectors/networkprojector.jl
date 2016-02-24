###################################################
## projectors/networkprojector.jl
## link geographical and network data
###################################################

"""
    `NetworkProjector`: abstract type that creates a link between NetworkData and GeoData
    is used to project geographical data onto network and to use network results
    must implement attributes:
    - `network::Network`
    - `trips::GeoData` : reference to trip data
    methods:
    - `preloadData!`: takes GeoData and load it
    - `getNetworkTrips`: returns network trips associated with given geo-trips
    - `getTripTiming` : returns timing estimation for a geographical trip (random or known)
"""
abstract NetworkProjector

function Base.show(io::IO, p::NetworkProjector)
    typeName = split(string(typeof(p)),".")[end]
    nTrips = length(p.trips)
    println(io,"Network Projector: $(typeName)")
    println(io,"$nTrips trips pre-loaded")
end

"""
    `NetworkData` : convenience function to create NetworkData using Projector
"""
function NetworkData(
        proj::NetworkProjector,
        trips::AbstractArray{Int64,1} = eachindex(proj.trips),
        minTimes::AbstractArray{Float64,2} = maxSpeedTimes(proj.network))
    # Create the "NetworkTrip" array
    return NetworkData(proj.network, getNetworkTrips(proj, trips), minTimes)
end
