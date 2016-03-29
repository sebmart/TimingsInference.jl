###################################################
## network/iterative/heuristicTimes.jl
## Heuristic from MIT Senseable City Lab
###################################################

"""
    heuristicTimes :
    optimize travel times using Senseable City Heuristic
"""
function heuristicTimes(s::IterativeState)
	et = getPathTimes(s.timings)
	g = s.data.network.graph
    paths = s.paths
    tripData = s.trips
    roads = s.data.network.roads

    # compute relative error
    relErr = 0.
    for trip in tripData
    	relErr += abs(trip.time - et[trip.orig, trip.dest])/trip.time
    end
    relErr = relErr/length(tripData)
    # compute offset for each road
    offset = Dict{Tuple{Int, Int}, Float64}()
    for (i,trip) in enumerate(tripData)
    	for j = 1:(length(paths[i][1])-1)
    		key = (paths[i][1][j], paths[i][1][j+1])
    		if haskey(offset, key)
    			offset[key] += (et[trip.orig, trip.dest] - trip.time) * trip.weight
    		else
    			offset[key] = (et[trip.orig, trip.dest] - trip.time) * trip.weight
    		end
    	end
    end
    # set initial value for k
    k = 1.2
    times = spzeros(nNodes(s.data.network), nNodes(s.data.network))
    # use offsets go update road times
    while true
    	# update roadTimes
    	for roadKey in keys(offset)
    		if offset[roadKey] < 0
	    		times[roadKey[1], roadKey[2]] = k * s.timings.times[roadKey[1], roadKey[2]]
	    	else
	    		times[roadKey[1], roadKey[2]] = s.timings.times[roadKey[1], roadKey[2]]/k
	    	end
    	end
    	# compute new error and see if it is better than the old one
    	newErr = 0.
    	for (i, trip) in enumerate(tripData)
    		estTime = 0.
    		for j = 1:(length(paths[i][1])-1)
    			estTime += times[paths[i][1][j], paths[i][1][j+1]]
    		end
    		newErr += abs(trip.time - estTime)/trip.time
    	end
    	if newErr < relErr
    		break
    	else
    		k = 1 + (k - 1) * 0.75
    		k < 1.0001 && break
    	end
    end
    # compute times for roads that did not appear in any path
    println("We have $(length(roads)-length(offset)) roads that did not appear in any path.")
    unknownRoads = Tuple{Int,Int}[]
    for key in keys(roads)
    	!(haskey(offset, key)) && push!(unknownRoads, key)
    end

    # find most connected road, update its time and repeat
    while length(unknownRoads) > 0
        maxIsct = 0
        maxIndex = 0
        for (i, roadKey) in enumerate(unknownRoads)
            isct = 0
    		for neighbor in RoutingNetworks.in_neighbors(g, roadKey[1])
                if !((neighbor, roadKey[1]) in unknownRoads)
                    isct += 1
                end
            end
            for neighbor in RoutingNetworks.out_neighbors(g, roadKey[2])
                if !((roadKey[2], neighbor) in unknownRoads)
                    isct += 1
                end
            end
            if isct > maxIsct
                maxIsct = isct
                maxIndex = i
            end
    	end
        newRoad = unknownRoads[maxIndex]
        neighborV = 0.
        count = 0
        for neighbor in RoutingNetworks.in_neighbors(g, newRoad[1])
            if !((neighbor, newRoad[1]) in unknownRoads)
                neighborV += times[neighbor, newRoad[1]]/roads[(neighbor, newRoad[1])].distance
                count += 1
            end
        end
        for neighbor in RoutingNetworks.out_neighbors(g, newRoad[2])
            if !((newRoad[2], neighbor) in unknownRoads)
                neighborV += times[newRoad[2], neighbor]/roads[(newRoad[2], neighbor)].distance
                count += 1
            end
        end
        times[newRoad[1], newRoad[2]] = roads[newRoad].distance/neighborV
        splice!(unknownRoads, maxIndex)
    end
    if k < 1.0001
        println("Convergence obtained")
    end
    return times
end
