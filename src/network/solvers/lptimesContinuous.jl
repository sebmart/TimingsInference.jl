###################################################
## network/solvers/lptimesContinuous.jl
## Simple LP method for travel time inference with continuity constraints
###################################################

"""
    `lpTimesContinuous`, optimize travel times to minimize L1 error from data with given paths
    with additional continuity constraints
"""
function lpTimesContinuous(s::IterativeState, velocityBound::Float64 = 0.5; args...) #args is solver args
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips
    roads = s.data.network.roads

    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = GurobiSolver(TimeLimit=10000, Crossover = 0, Method=2, BarConvTol=1e-8; args...))

    # DECISION VARIABLES
    # Road times
    @defVar(m, t[i=vertices(g), j=out_neighbors(g,i)] >= s.data.minTimes[i,j])
    # Absolute difference between tripData times and computed times
    @defVar(m, epsilon[d=eachindex(tripData)] >= 0)

    # OBJECTIVE
    @setObjective(m, Min, sum{ sqrt(tripData[d].weight/tripData[d].time)*epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # absolute values contraints (define epsilon), equal to time of first path
    @addConstraint(m, epsLower[d=eachindex(tripData)],
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} - tripData[d].time >=
        - epsilon[d])
    @addConstraint(m, epsUpper[d=eachindex(tripData)],
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} - tripData[d].time <=
        epsilon[d])

    # inequality constraints
    @addConstraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
        sum{paths[d][p+1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][p+1])} >=
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])}
        )

    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))

    continuous = false
    while !continuous
        # SOLVE LP
        status = solve(m)
        times = getValue(t)
        for i in vertices(g), j in out_neighbors(g,i)
            result[i,j] = times[i,j]
        end
        counter = 0
        for i in vertices(g), j in out_neighbors(g,i)
            for edge in findNearEdges(s.data.network, Edge(i,j))
                p = src(edge)
                q = dst(edge)
                if roads[i,j].roadType == roads[p, q].roadType &&
                    abs(result[i,j]/roads[i,j].distance - result[p,q]/roads[p,q].distance) > velocityBound
                    @addConstraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                        <= velocityBound)
                    @addConstraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                        >= -velocityBound)
                    counter += 1
                end
            end
        end
        if counter > 500
            continuous = false
        else
            continuous = true
        end
    end
    return result
end