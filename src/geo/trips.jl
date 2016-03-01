###################################################
## geo/trips.jl
## types representing trips
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