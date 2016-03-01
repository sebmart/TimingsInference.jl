###################################################
## geo/timings/knn.jl
## Data-driven timings estimator, K-nearest-neighbors mean
###################################################


"""
    `KnnTimings`, K-nearest-neighbors timings estimator
"""
type KnnTimings <: GeoTimings
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
            px, py = toENU(trips[i].pLon, trips[i].pLat, gt.center)
            dx, dy = toENU(trips[i].dLon, trips[i].dLat, gt.center)
            dataPos[1, k] = px
            dataPos[2, k] = py
            dataPos[3, k] = dx
            dataPos[4, k] = dy
        end
        gt.tree = KDTree(dataPos)

        return gt
    end
end
KnnTimings(s::DataSplit, k::Int; args...) =  KnnTimings(s.geodata, trainSet(s), k; args...)

function estimateTime(gt::KnnTimings, pLon::Float32, pLat::Float32, dLon::Float32, dLat::Float32)
@inbounds begin
    px, py = toENU(pLon, pLat, gt.center)
    dx, dy = toENU(dLon, dLat, gt.center)
    idxs, dists = knn(gt.tree, [px, py, dx, dy], gt.k)
    if gt.weighted
        num = 0.
        denum = 0.
        for i in eachindex(idxs)
            if dists[i] == 0.
                return gt.trips[gt.trainset[idxs[i]]].time
            else
                num += gt.trips[gt.trainset[idxs[i]]].time / dists[i]
                denum += 1./dists[i]
            end
        end
        return num/denum
    else
        mean = 0.
        for id in idxs
            mean += gt.trips[gt.trainset[id]].time
        end
        return mean / length(idxs)
    end
end #inbounds
end
