###################################################
## geo/data/nyctaxi.jl
## Everything specific to the NYC taxi trip data
###################################################


"""
    `fromNYCTaxiData` : extract one month of trip information from original trip CSV
    Return GeoData object
"""
function fromNYCTaxiCSV(fileName::AbstractString)
    println("Counting lines...")
    f = open(fileName)
    const NLINES = countlines(f) - 1
    close(f)
    println("$NLINES trips to parse")

    trips = Array(GeoTrip, NLINES)
    dateFormat = DateFormat("y-m-d H:M:S")
    f = open(fileName)
    names = split(strip(readline(f)),",")
    const PLON  = findfirst(names, "pickup_longitude")
    const PLAT  = findfirst(names, "pickup_latitude")
    const DLON  = findfirst(names, "dropoff_longitude")
    const DLAT  = findfirst(names, "dropoff_latitude")
    const PTIME = findfirst(names, "tpep_pickup_datetime")
    const DTIME = findfirst(names, "tpep_dropoff_datetime")

    println("Beginning trip parsing...")
    for (i,ln) in enumerate(eachline(f))
        if i%10_000 == 0
            @printf("\r%.2f%% trips parsed     ",100*i/NLINES)
        end
        s = split(strip(ln),",")
        pTime = DateTime(s[PTIME], dateFormat)
        dTime = DateTime(s[DTIME], dateFormat)

        trips[i] = GeoTrip(
            parse(Float32,s[PLON]),
            parse(Float32,s[PLAT]),
            parse(Float32,s[DLON]),
            parse(Float32,s[DLAT]),
            pTime,
            ((dTime-pTime).value)/1000.f0
        )
    end
    print("\r100.00% trips parsed     ")
    return trips
end
