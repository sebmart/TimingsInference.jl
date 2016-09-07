###################################################
## geo/data/filters.jl
## Filtering geo-trips
###################################################

"""
    `removeBadTrips`: filter a `GeoTrip` list to remove outliers
"""
function removeOutliers(trips::GeoData)
    reg = Bool[isRegular(t) for t in trips]
    t = trips[reg]
    @printf("%.2f%% outliers removed\n", 100*(1-length(t)/length(trips)))
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
    #trips should be > 250m and < 200km
    if d <= 250. || d >= 200_000
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
    `inTimeWindow`: keep trips in a certain time window
    - time window is of the form "13:40","13:52" (here minute "52" is NOT included)
    - for GeoTrip object: returns boolean
    - for GeoData object: returns filtered GeoData object
"""
function inTimeWindow(t::GeoTrip, startHour::Int, startMin::Int, endHour::Int, endMin::Int)
    return ((startHour < Dates.hour(t.pTime) || 
        (startHour == Dates.hour(t.pTime) && startMin <= Dates.minute(t.pTime))) && 
    (endHour > Dates.hour(t.pTime) || 
        (endHour   == Dates.hour(t.pTime) && endMin > Dates.minute(t.pTime))))
end

function inTimeWindow(trips::GeoData, startHour::Int, startMin::Int, endHour::Int, endMin::Int)
    mask = BitArray(length(trips))
    for (i, t) in enumerate(trips)
        if i%10_000 == 0
            @printf("\r%.2f%% trips checked     ",100*i/length(trips))
        end
        mask[i] = inTimeWindow(t, startHour, startMin, endHour, endMin)
    end
    newTrips = trips[mask]
    @printf("\r%2.f%% trips removed\n", 100*(1-length(newTrips)/length(trips)))
    return newTrips
end

function inTimeWindow(trips::GeoData, startTime::AbstractString, endTime::AbstractString)
    s = split(startTime,":")
    e = split(endTime,  ":")
    startHour = parse(Int, s[1])
    endHour   = parse(Int, e[1])
    startMin = parse(Int, s[2])
    endMin   = parse(Int, e[2])
    return inTimeWindow(trips, startHour, startMin, endHour, endMin)
end

"""
    `onlyWeekdays`: keep trips that occur on weekdays
    - for GeoTrip object: returns boolean
    - for GeoData object: returns filtered GeoData object
"""
function onlyWeekdays(t::GeoTrip)
    return Dates.dayofweek(t.pTime) < 6
end

function onlyWeekdays(trips::GeoData)
    mask = BitArray(length(trips))
    for (i, t) in enumerate(trips)
        if i%10_000 == 0
            @printf("\r%.2f%% trips checked     ",100*i/length(trips))
        end
        mask[i] = onlyWeekdays(t)
    end
    newTrips = trips[mask]
    @printf("\r%.2f%% trips removed\n", 100*(1-length(newTrips)/length(trips)))
    return newTrips
end

"""
    `onlyWeekends`: keep trips that occur on weekends
    - for GeoTrip object: returns boolean
    - for GeoData object: returns filtered GeoData object
"""
function onlyWeekends(t::GeoTrip)
    return Dates.dayofweek(t.pTime) > 5
end

function onlyWeekends(trips::GeoData)
    mask = BitArray(length(trips))
    for (i, t) in enumerate(trips)
        if i%10_000 == 0
            @printf("\r%.2f%% trips checked     ",100*i/length(trips))
        end
        mask[i] = onlyWeekends(t)
    end
    newTrips = trips[mask]
    @printf("\r%.2f%% trips removed\n", 100*(1-length(newTrips)/length(trips)))
    return newTrips
end

"""
    `inPolygon`: keep trips with pickup and dropoff inside a polygon
    - for one trip: returns boolean
    - for trip list: returns filtered list
"""
function inPolygon(t::GeoTrip, poly::Vector{Tuple{Float32,Float32}})
    return pointInsidePolygon(t.pLon,t.pLat,poly) && pointInsidePolygon(t.dLon,t.dLat,poly)
end

function inPolygon(trips::GeoData, poly::Vector{Tuple{Float32,Float32}})
    mask = BitArray(length(trips))
    for (i,t) in enumerate(trips)
        if i%10_000 == 0
            @printf("\r%.2f%% trips checked     ",100*i/length(trips))
        end
        mask[i] = inPolygon(t,poly)
    end
    t = trips[mask]
    @printf("\r%.2f%% trips removed\n", 100*(1-length(t)/length(trips)))
    return t
end

"""
    `getPolygon`: given a name, returns the associated geographical polygon
    - For now, just a few so hardcoded, later: perhaps file system
"""
function getPolygon(name::AbstractString)
    if name == "Manhattan"
        return Tuple{Float32,Float32}[(-74.01369f0,40.69977f0), (-74.00597f0,40.702637f0), (-73.99944f0,40.70641f0), (-73.991714f0,40.708492f0), (-73.9761f0,40.71044f0), (-73.96923f0,40.72931f0), (-73.973526f0,40.736073f0), (-73.9615f0,40.75402f0), (-73.941765f0,40.774693f0), (-73.94348f0,40.78223f0), (-73.938156f0,40.78535f0), (-73.93593f0,40.79029f0), (-73.928894f0,40.79432f0), (-73.92872f0,40.803024f0), (-73.93318f0,40.80744f0), (-73.9349f0,40.833942f0), (-73.92134f0,40.85745f0), (-73.91893f0,40.858356f0), (-73.913956f0,40.863678f0), (-73.909706f0,40.872345f0), (-73.91829f0,40.875168f0), (-73.92648f0,40.879192f0), (-73.93344f0,40.87244f0), (-73.933525f0,40.86793f0), (-73.943436f0,40.853584f0), (-73.947945f0,40.85164f0), (-73.94713f0,40.84414f0), (-73.9552f0,40.828682f0), (-73.96091f0,40.8205f0), (-73.97734f0,40.79864f0), (-73.98957f0,40.78077f0), (-73.996994f0,40.770725f0), (-74.00352f0,40.761368f0), (-74.01064f0,40.75103f0), (-74.01532f0,40.719486f0), (-74.01764f0,40.719063f0), (-74.02047f0,40.704067f0)]
    elseif name == "Cambridge"
        return Tuple{Float32,Float32}[(-71.16033f0,42.386353f0),(-71.158035f0,42.386974f0),(-71.15701f0,42.390144f0),(-71.15843f0,42.394585f0),(-71.15651f0,42.39574f0),(-71.1521f0,42.401054f0),(-71.143326f0,42.397266f0),(-71.14316f0,42.39773f0),(-71.14065f0,42.399643f0),(-71.13947f0,42.40012f0),(-71.137825f0,42.400192f0),(-71.13676f0,42.400776f0),(-71.13567f0,42.401546f0),(-71.13397f0,42.40376f0),(-71.1313f0,42.401585f0),(-71.12433f0,42.393604f0),(-71.122856f0,42.39224f0),(-71.12096f0,42.393703f0),(-71.11933f0,42.391636f0),(-71.11706f0,42.38956f0),(-71.11798f0,42.389065f0),(-71.11744f0,42.388367f0),(-71.11818f0,42.388f0),(-71.11549f0,42.38504f0),(-71.11169f0,42.38177f0),(-71.110695f0,42.381683f0),(-71.10785f0,42.379375f0),(-71.108444f0,42.37912f0), (-71.10324f0,42.374348f0),(-71.09753f0,42.374443f0),(-71.09374f0,42.374264f0),(-71.0898f0,42.373955f0),(-71.08607f0,42.37305f0),(-71.08542f0,42.374054f0),(-71.08495f0,42.37346f0),(-71.08441f0,42.373302f0),(-71.08241f0,42.37341f0),(-71.0812f0,42.374058f0),(-71.08036f0,42.37412f0),(-71.079956f0,42.37381f0),(-71.07899f0,42.374172f0),(-71.077545f0,42.373566f0),(-71.075966f0,42.374027f0),(-71.07429f0,42.372536f0),(-71.07267f0,42.373222f0),(-71.07242f0,42.37263f0),(-71.066795f0,42.37184f0),(-71.06405f0,42.369076f0),(-71.06958f0,42.368954f0),(-71.07437f0,42.363743f0),(-71.07485f0,42.3619f0),(-71.07669f0,42.359463f0),(-71.0778f0,42.35864f0),(-71.07809f0,42.357986f0),(-71.08976f0,42.35472f0),(-71.09736f0,42.353386f0),(-71.107574f0,42.35257f0),(-71.10974f0,42.352524f0),(-71.11314f0,42.35298f0),(-71.11584f0,42.354397f0),(-71.117035f0,42.355972f0),(-71.116554f0,42.35941f0),(-71.11706f0,42.3666f0),(-71.11738f0,42.367508f0),(-71.11807f0,42.368336f0),(-71.11947f0,42.36878f0),(-71.12224f0,42.3687f0),(-71.12363f0,42.36908f0),(-71.12459f0,42.369778f0),(-71.12699f0,42.37273f0),(-71.128426f0,42.37367f0),(-71.12929f0,42.37393f0),(-71.130936f0,42.373913f0),(-71.13242f0,42.373425f0),(-71.133194f0,42.37248f0),(-71.13313f0,42.371937f0),(-71.13185f0,42.370285f0),(-71.13181f0,42.369446f0),(-71.132256f0,42.369034f0),(-71.13574f0,42.367092f0),(-71.138954f0,42.364475f0),(-71.14051f0,42.364162f0),(-71.14258f0,42.36476f0),(-71.1436f0,42.364784f0),(-71.14434f0,42.366383f0),(-71.14249f0,42.36688f0),(-71.140976f0,42.369232f0),(-71.14038f0,42.370716f0),(-71.14004f0,42.373566f0),(-71.14396f0,42.374046f0),(-71.14367f0,42.37525f0),(-71.14969f0,42.374554f0),(-71.15439f0,42.37506f0),(-71.15627f0,42.38064f0),(-71.15507f0,42.38021f0),(-71.1552f0,42.38119f0),(-71.15759f0,42.38206f0),(-71.16033f0,42.386353f0)]
    else
        error("Polygon $name not found")
    end
end
