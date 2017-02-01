###################################################
## network/tools/yenksp.jl
## Yen's K-shortest path algorithm
###################################################

immutable HeapEntry
  path::Vector{Int}
  length::Float64
end

# define appropriate comparators for heap entries
isless(e1::HeapEntry, e2::HeapEntry) = e1.length < e2.length
<(e1::HeapEntry, e2::HeapEntry) = e1.length < e2.length

"""
    `getPathFromParents(parents, orig, dest)`
    Returns path between origin and destination (list of node ids)
"""
function getPathFromParents(parents::Vector{Int}, orig::Int, dest::Int)
    path = Int[dest]
    lastNode = dest
    while lastNode != orig
        lastNode = parents[lastNode]
        push!(path, lastNode)
    end
    return path[end:-1:1]
end

"""
    `yenKSP`: Yen's K-shortest path algorithm
    Args:
        - timings   : NetworkTimings object (cost function of network)
        - t         : Network Trip for which we want to find paths
        - k         : number of shortest paths
    Returns:
        - vector of paths. each path is represented as a vector of edges
"""
function yenKSP(timings::NetworkTimings, t::NetworkTrip, k::Int)
    orig = t.orig[2]
    dest = t.dest[1]
    # check if dijkstra shortest paths have been computed already
    if !isdefined(timings, :pathTimes)
        error("The paths have not been computed yet")
    end
    pathList = Vector{Int}[getPath(timings, orig, dest)]
    # heap of new paths
    h = HeapEntry[]
    H = mutable_binary_minheap(h)
    # find k-1 more paths
    for i = 2:k
        # for every node in last path
        for (j, node) in enumerate(pathList[i-1][1:(end-1)])
            times = copy(timings.times)
            rootPath = pathList[i-1][1:j]
            for path in pathList
                if length(path) >= j && path[1:j] == rootPath
                    times[node, path[j+1]] = Inf
                end
            end
            for spurNode in rootPath
                for prev in RoutingNetworks.in_neighbors(timings.network.graph, spurNode)
                    times[prev,spurNode] = Inf
                end
            end
            d = dijkstra_shortest_paths(timings.network.graph, node, times)
            if d.dists[dest] < Inf
                append!(rootPath, getPathFromParents(d.parents, node, dest)[2:end])
                if !(rootPath in pathList)
                    push!(H, HeapEntry(rootPath, pathTime(timings, rootPath)))
                end
            end
        end
        if length(H) == 0
            break
        else
            newPathEntry = pop!(H)
            while newPathEntry.path in pathList
                newPathEntry = pop!(H)
            end
            push!(pathList, newPathEntry.path)
        end
    end
    pathEdgesList = [toPathEdgesDict(t, path) for path in pathList]
    return pathEdgesList
end

"""
    `yenKSP`: Yen's K-shortest path algorithm
    Same as above except for a vector of network trips
"""
function yenKSP(timings::NetworkTimings, trips::Vector{NetworkTrip}, k::Int)
    if nworkers() <= 1
        paths = Array(Vector{Dict{Edge,Float64}}, length(trips))
        for (i,t) in enumerate(trips)
            paths[i] = yenKSP(timings, t, k)
        end
    else
        paths = SharedArray(Vector{Dict{Edge, Float64}}, length(trips))
        @sync @parallel for (i,t) in enumerate(trips)
            paths[i] = yenKSP(timings, t, k)
        end
    end
    return paths
end
