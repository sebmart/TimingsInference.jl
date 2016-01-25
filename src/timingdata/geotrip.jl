###################################################
## geotrip.jl
## Representing trip data with continuous geographical locations
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
