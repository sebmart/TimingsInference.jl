###################################################
## network/solvers/lpCo.jl
## Simple LP method for travel time inference with continuity constraints
###################################################

"""
    `lpTimesCont`, optimize travel times to minimize L1 error from data with given paths
    with additional continuity constraints
"""
function lpTimesCont(s::IterativeState, velocityBound::Float64 = 0.1; args...) #args is solver args
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips
    roads = s.data.network.roads

    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = GurobiSolver(TimeLimit=10000, Method=2, Crossover=0, BarConvTol=1e-8; args...))

    # DECISION VARIABLES
    # Road times
    @variable(m, t[i=vertices(g), j=out_neighbors(g,i)] >= s.data.minTimes[i,j])
    # Absolute difference between tripData times and computed times
    @variable(m, epsilon[d=eachindex(tripData)] >= 0)

    # OBJECTIVE
    @objective(m, Min, sum{ sqrt(tripData[d].weight/tripData[d].time)*epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # absolute values contraints (define epsilon), equal to time of first path
    @constraint(m, epsLower[d=eachindex(tripData)],
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} - tripData[d].time >=
        - epsilon[d])
    @constraint(m, epsUpper[d=eachindex(tripData)],
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} - tripData[d].time <=
        epsilon[d])

    # inequality constraints
    @constraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
        sum{paths[d][p+1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][p+1])} >=
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])}
        )

    # continuity constraints
    for i in vertices(g), j in out_neighbors(g,i)
        for edge in findNearEdgesSameType(s.data.network, Edge(i,j))
            p = src(edge)
            q = dst(edge)
            @constraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                <= velocityBound)
            @constraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                >= -velocityBound)
        end
    end

    # SOLVE LP
    status = solve(m)
    times = getValue(t)

    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))
    for i in vertices(g), j in out_neighbors(g,i)
        result[i,j] = times[i,j]
    end

    return result
end
