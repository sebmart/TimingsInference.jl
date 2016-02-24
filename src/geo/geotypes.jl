###################################################
## geo/geotypes.jl
## types representing geo data and geo timings estimators
###################################################

"""
    `GeoTrip` : data for one geographical trip
"""
immutable GeoTrip
    "pick-up lonlat coordinates"
    pLon::Float32
    pLat::Float32

    "drop-off lonlat coordinates"
    dLon::Float32
    dLat::Float32

    "Pick-up date and time"
    pTime::DateTime

    "Trip time (seconds)"
    time::Float32
end
function Base.show(io::IO, t::GeoTrip)
    print(io,"$(t.pTime) -- ($(t.pLon),$(t.pLat))=>($(t.dLon),$(t.dLat)): $(tripDistance(t))m in $(t.time)s ")
end

"""
    `GeoData`: list of `GeoTrip`
"""
typealias GeoData Vector{GeoTrip}

"""
    `stats`: print information
"""
function stats(t::GeoData)
    println("GeoData: trip information in GPS coordinates")
    println("--- $(length(t)) trips: $(sizeof(t)/1e6)MB")
end

"""
    `GeoTimings`, abstract type that represents an estimator of timings in continuous setting
    must contain:
    - `trips`, reference to trip data that may be used
    must implement:
    - `estimateTime`, estimate time between two points, or for a trip
"""
abstract GeoTimings

function Base.show(io::IO, p::GeoTimings)
    typeName = split(string(typeof(p)),".")[end]
    nTrips = length(p.trips)
    println(io,"Continuous timings: $(typeName)")
    println(io,"$nTrips trips pre-loaded")
end

"""
    `estimateTime`, estimate time of continuous trip
"""
estimateTime(gt::GeoTimings, o::Tuple{Float32, Float32}, d::Tuple{Float32, Float32})=
estimateTime(gt,o[1],o[2],d[1],d[2])
estimateTime(gt::GeoTimings, t::GeoTrip) =
estimateTime(gt, t.pLon, t.pLat, t.dLon, t.dLat)
estimateTime(gt::GeoTimings, i::Int) =
estimateTime(gt, gt.trips[i])
