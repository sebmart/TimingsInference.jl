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
    NLINES = countlines(f) - 1
    close(f)
    println("$NLINES trips to parse")

    trips = Array{GeoTrip}(undef, NLINES)
    dateFormat = DateFormat("y-m-d H:M:S")
    f = open(fileName)
    names = split(strip(readline(f)),",")
    PLON  = findfirst(isequal("pickup_longitude"), names)
    PLAT  = findfirst(isequal("pickup_latitude"), names)
    DLON  = findfirst(isequal("dropoff_longitude"), names)
    DLAT  = findfirst(isequal("dropoff_latitude"), names)
    PTIME = findfirst(isequal("tpep_pickup_datetime"), names)
    DTIME = findfirst(isequal("tpep_dropoff_datetime"), names)

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
