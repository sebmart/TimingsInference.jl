###################################################
## networkprojector.jl
## link geographical and network data
###################################################

"""
    `NetworkProjector`: abstract type that the link between NetworkData and GeoData
    must implements attributes:
    - `network::Network`
    - `trips::TripData` : reference to trip data
    methods:
    - constructor that takes at least rides and trips
    - `NetworkData` to give network data object
"""
abstract NetworkProjector
