###################################################
## geo/timings/fromnetwork.jl
## extends NetworkTimings object to continuous timings, using a projector
###################################################

"""
    `TimingsFromNetwork`, uses projector to extend timings from network
"""
type TimingsFromNetwork <: GeoTimings
    trips::GeoData # compulsary attribute

    "timings in network"
    timings::NetworkTimings
    "Projector that links network timings to continuous timings"
    proj::NetworkProjector

    function TimingsFromNetwork(nt::NetworkTimings, proj::NetworkProjector)
        gt = new()
        gt.trips = proj.trips
        gt.timings = nt
        gt.proj  = proj
        return gt
    end
end

estimateTime(gt::TimingsFromNetwork, pLon::Float32, pLat::Float32, dLon::Float32, dLat::Float32)=
    getTripTiming(gt.proj, gt.timings, pLon, pLat, dLon, dLat)

estimateTime(gt::TimingsFromNetwork, tId::Int) =
    getTripTiming(gt.proj, gt.timings, tId)
