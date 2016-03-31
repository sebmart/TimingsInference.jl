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
        newErr = newErr/length(tripData)
    	if newErr < relErr
    		break
    	else
    		k = 1 + (k - 1) * 0.75
    		k < 1.0001 && break
    	end
    end
    if k < 1.0001
        println("Convergence obtained")
    end
    # compute times for roads that did not appear in any path
    println("We have $(length(roads)-length(offset)) roads that did not appear in any path.")
    unknownRoads = Dict{Tuple{Int,Int}, Int}()
    for (key, road) in roads
    	if !(haskey(offset, key))
            unknownRoads[key] = 0
        end
    end
    for key in keys(unknownRoads) 
        for neighbor in RoutingNetworks.in_neighbors(g, key[1])
            if !((neighbor, key[1]) in keys(unknownRoads))
                unknownRoads[key] += 1
            end
        end
        for neighbor in RoutingNetworks.out_neighbors(g, key[2])
            if !((key[2], neighbor) in keys(unknownRoads))
                unknownRoads[key] += 1
            end
        end
    end

    # find most connected road, update its time and repeat
    while length(unknownRoads) > 0
        maxValue = 0
        maxKey = 0
        for (key, value) in unknownRoads
            if value > maxValue
                maxValue = value
                maxKey = key
            end
    	end
        newRoad = maxKey
        neighborV = 0.
        count = 0
        for neighbor in RoutingNetworks.in_neighbors(g, newRoad[1])
            if (neighbor, newRoad[1]) in keys(unknownRoads)
                unknownRoads[(neighbor, newRoad[1])] += 1
            else
                neighborV += times[neighbor, newRoad[1]]/roads[(neighbor, newRoad[1])].distance
                count += 1
            end
        end
        for neighbor in RoutingNetworks.out_neighbors(g, newRoad[2])
            if (newRoad[2], neighbor) in keys(unknownRoads)
                unknownRoads[(newRoad[2], neighbor)] += 1
            else
                neighborV += times[newRoad[2], neighbor]/roads[(newRoad[2], neighbor)].distance
                count += 1
            end
        end
        neighborV = neighborV/count
        times[newRoad[1], newRoad[2]] = roads[newRoad].distance/neighborV
        delete!(unknownRoads, newRoad)
    end
    return times
end
