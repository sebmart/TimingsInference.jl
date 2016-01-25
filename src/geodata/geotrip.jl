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
function Base.show(io::IO, t::GeoTrip)
    print(io,"$(t.pTime) -- ($(t.pLon),$(t.pLat))=>($(t.dLon),$(t.dLat)): $(tripDistance(t))m in $(t.time)s ")
end

"""
    `TripData`: list of `GeoTrip`
"""
typealias TripData Vector{GeoTrip}

function Base.show(io::IO, t::TripData)
    println("TripData: trip information in GPS coordinates")
    println("--- $(length(trips)) trips: $(sizeof(trips)/1e6)MB")
end

"""
    `removeBadTrips`: filter a `GeoTrip` list to remove outliers
"""
function removeOutliers(trips::TripData)
    reg = Bool[isRegular(t) for t in trips]
    t = trips[reg]
    @printf("%2.f%% outliers removed\n", 100*(1-length(t)/length(trips)))
    return t
end

"""
    `isRegular`: returns false if the trip is an "outlier"
"""
function isRegular(t::GeoTrip)
    #trips should be > 30s and <3h
    if t.time <= 30. || t.time >= 3*3600.
        return false
    end
    d = tripDistance(t)
    #trips should be > 200m and < 200km
    if d <= 200. || d >= 200_000
        return false
    end
    #  direct speed <= 110 km/h, >= 2km/h
    s = d*3.6/t.time
    if s > 110. || s < 2.
        return false
    end
    return true
end

"""
    `tripDistance`: compute line distance for one GeoTrip
"""
tripDistance(t::GeoTrip) = distanceGeo(t.pLon,t.pLat,t.dLon,t.dLat)

"""
    `inPolygon`: keep trips with pickup and dropoff inside a polygon
    - for one trip: returns boolean
    - for trip list: returns filtered list
"""
function inPolygon(t::GeoTrip, poly::Vector{Tuple{Float32,Float32}})
    return pointInsidePolygon(t.pLon,t.pLat,poly) && pointInsidePolygon(t.dLon,t.dLat,poly)
end

function inPolygon(trips::TripData, poly::Vector{Tuple{Float32,Float32}})
    mask = BitArray(length(trips))
    for (i,t) in enumerate(trips)
        if i%10_000 == 0
            @printf("\r%.2f%% trips checked     ",100*i/length(trips))
        end
        mask[i] = inPolygon(t,poly)
    end
    t = trips[mask]
    @printf("\n%2.f%% trips removed\n", 100*(1-length(t)/length(trips)))
    return t
end

"""
    `getPolygon`: given a name, returns the associated geographical polygon
    - For now, just a few so hardcoded, later: perhaps file system
"""
function getPolygon(name::AbstractString)
    if name == "Manhattan"
        return Tuple{Float32,Float32}[(-74.01369f0,40.69977f0), (-74.00597f0,40.702637f0), (-73.99944f0,40.70641f0), (-73.991714f0,40.708492f0), (-73.9761f0,40.71044f0), (-73.96923f0,40.72931f0), (-73.973526f0,40.736073f0), (-73.9615f0,40.75402f0), (-73.941765f0,40.774693f0), (-73.94348f0,40.78223f0), (-73.938156f0,40.78535f0), (-73.93593f0,40.79029f0), (-73.928894f0,40.79432f0), (-73.92872f0,40.803024f0), (-73.93318f0,40.80744f0), (-73.9349f0,40.833942f0), (-73.92134f0,40.85745f0), (-73.91893f0,40.858356f0), (-73.913956f0,40.863678f0), (-73.909706f0,40.872345f0), (-73.91829f0,40.875168f0), (-73.92648f0,40.879192f0), (-73.93344f0,40.87244f0), (-73.933525f0,40.86793f0), (-73.943436f0,40.853584f0), (-73.947945f0,40.85164f0), (-73.94713f0,40.84414f0), (-73.9552f0,40.828682f0), (-73.96091f0,40.8205f0), (-73.97734f0,40.79864f0), (-73.98957f0,40.78077f0), (-73.996994f0,40.770725f0), (-74.00352f0,40.761368f0), (-74.01064f0,40.75103f0), (-74.01532f0,40.719486f0), (-74.01764f0,40.719063f0), (-74.02047f0,40.704067f0)]
    else
        error("Polygon $name not found")
    end
end
