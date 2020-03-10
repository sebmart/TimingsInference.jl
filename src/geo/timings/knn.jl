###################################################
## geo/timings/knn.jl
## Data-driven timings estimator, K-nearest-neighbors mean
###################################################


"""
    `KnnTimings`, K-nearest-neighbors timings estimator
"""
mutable struct KnnTimings <: GeoTimings
    trips::GeoData # compulsary attribute

    "number of neighbors to average"
    k::Int
    "kdd tree to search for nearest neighbors"
    tree::KDTree
    "center of projection"
    center::Tuple{Float32, Float32}
    "if we are weighting the mean by the distance"
    weighted::Bool
    "training set indices"
    trainset::Vector{Int}

    function KnnTimings(trips::GeoData, trainSet::AbstractArray{Int}, k::Int; weighted::Bool=false)
        gt = new()
        gt.trips = trips
        gt.k = k
        gt.weighted = weighted
        gt.trainset = trainSet
        # create center for projection
        minLat, maxLat, minLon, maxLon = Inf32, -Inf32, Inf32, -Inf32
        for t in trips
            minLat > t.pLat && (minLat = t.pLat)
            minLat > t.dLat && (minLat = t.dLat)
            minLon > t.pLon && (minLon = t.pLon)
            minLon > t.dLon && (minLon = t.dLon)
            maxLat < t.pLat && (maxLat = t.pLat)
            maxLat < t.dLat && (maxLat = t.dLat)
            maxLon < t.pLon && (maxLon = t.pLon)
            maxLon < t.dLon && (maxLon = t.dLon)
        end
        gt.center = ((maxLon + minLon)/2, (maxLat + minLat)/2)
        println("Creating KDTree...")
        dataPos = Array(Float64,(4, length(trainSet)))
        for (k,i) in enumerate(trainSet)
            if (k % 100_000) == 0
                @printf("\r%.2f%% trips loaded     ",100*k/length(trainSet))
            end
            px, py = toENU(trips[i].pLon, trips[i].pLat, gt.center)
            dx, dy = toENU(trips[i].dLon, trips[i].dLat, gt.center)
            dataPos[1, k] = px
            dataPos[2, k] = py
            dataPos[3, k] = dx
            dataPos[4, k] = dy
        end
        println("\r100.00% trips loaded      ")
        gt.tree = KDTree(dataPos)

        return gt
    end
end
KnnTimings(s::DataSplit, k::Int; args...) =  KnnTimings(s.geodata, trainSet(s), k; args...)

"""
    `estimateTime`: Implementation of required method for GeoTimings
"""
function estimateTime(gt::KnnTimings, pLon::Float32, pLat::Float32, dLon::Float32, dLat::Float32)
@inbounds begin
    px, py = toENU(pLon, pLat, gt.center)
    dx, dy = toENU(dLon, dLat, gt.center)
    idxs, dists = knn(gt.tree, [px, py, dx, dy], gt.k)
    if gt.weighted
        num = 1.0
        denum = 0.
        for i in eachindex(idxs)
            if dists[i] == 0.
                return gt.trips[gt.trainset[idxs[i]]].time
            else
                num *= gt.trips[gt.trainset[idxs[i]]].time ^ (1/ dists[i])
                denum += 1.0/dists[i]
            end
        end
        return num^(1/denum)
    else
        mean = 1.0
        for id in idxs
            mean *= gt.trips[gt.trainset[id]].time
        end
        return mean^(1.0/length(idxs))
    end
end #inbounds
end

"""
    `estimateTimeWithDistance`: Alternate version of estimateTime that also returns average distance from point to neighbors
"""
function estimateTimeWithDistance(gt::KnnTimings, pLon::Float32, pLat::Float32, dLon::Float32, dLat::Float32)
@inbounds begin
    px, py = toENU(pLon, pLat, gt.center)
    dx, dy = toENU(dLon, dLat, gt.center)
    idxs, dists = knn(gt.tree, [px, py, dx, dy], gt.k)
    if gt.weighted
        num = 1.0
        denum = 0.
        for i in eachindex(idxs)
            if dists[i] == 0.
                return gt.trips[gt.trainset[idxs[i]]].time
            else
                num *= gt.trips[gt.trainset[idxs[i]]].time ^ (1/ dists[i])
                denum += 1.0/dists[i]
            end
        end
        return num^(1/denum), sum(dists)/length(dists)
    else
        mean = 1.0
        for id in idxs
            mean *= gt.trips[gt.trainset[id]].time
        end
        return mean^(1/length(idxs)), sum(dists)/length(dists)
    end
end #inbounds
end

estimateTimeWithDistance(gt::KnnTimings, tripID::Int) = estimateTimeWithDistance(gt, gt.trips[tripID].pLon, gt.trips[tripID].pLat, gt.trips[tripID].dLon, gt.trips[tripID].dLat)
