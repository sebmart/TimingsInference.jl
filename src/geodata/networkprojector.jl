###################################################
## networkprojector.jl
## link geographical and network data
###################################################

"""
    `NetworkProjector`: abstract type that the link between NetworkData and GeoData
    is used to project geographical data onto network and to use network results
    must implements attributes:
    - `network::Network`
    - `trips::TripData` : reference to trip data
    methods:
"""
abstract NetworkProjector



type NearestNode <: NetworkProjector
    # compulsory attributes
    network::Network

end
