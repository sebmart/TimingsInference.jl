###################################################
## geo/timings/geotimings.jl
## abstract geotimings definition
###################################################

"""
    `GeoTimings`, abstract type that represents an estimator of timings in continuous setting
    must contain:
    - `trips`, reference to trip data that may be used
    must implement:
    - `estimateTime`, estimate time between two points, or for a trip
"""
abstract type GeoTimings end

function Base.show(io::IO, p::GeoTimings)
    typeName = split(string(typeof(p)),".")[end]
    println(io,"Continuous timings: $(typeName)")
end

"""
    `estimateTime`, estimate time of continuous trip
"""
estimateTime(gt::GeoTimings, o::Tuple{Float32, Float32}, d::Tuple{Float32, Float32})=
estimateTime(gt,o[1],o[2],d[1],d[2])
estimateTime(gt::GeoTimings, t::GeoTrip) =
estimateTime(gt, t.pLon, t.pLat, t.dLon, t.dLat)
estimateTime(gt::GeoTimings, tId::Int) =
estimateTime(gt, gt.trips[tId])
estimateTime(gt::GeoTimings, list::AbstractArray{Int,1}) =
Float64[estimateTime(gt, tId) for tId in list]
