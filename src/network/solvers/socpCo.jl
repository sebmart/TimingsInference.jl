###################################################
## network/solvers/socpCo.jl
## SOCP that finds new traveltimes to optimize cost function
###################################################


"""
    socpTimesCont :
    optimize travel times to minimize L1 error from data with given paths
"""
function socpTimesCont(s::IterativeState, velocityBound::Float64 = 0.1; args...)
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips
    roads = s.data.network.roads

    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = MosekSolver(MSK_DPAR_OPTIMIZER_MAX_TIME=10000., MSK_IPAR_INFEAS_REPORT_AUTO = MSK_ON; args...))

    # DECISION VARIABLES
    # Road times
    @variable(m, t[i=vertices(g), j=out_neighbors(g,i)] >= s.data.minTimes[i,j])
    # Absolute difference between tripData times and computed times
    @variable(m, epsilon[d=eachindex(tripData)] >= 0)
    @variable(m, T[d=eachindex(tripData)] >= 0)

    # OBJECTIVE
    @objective(m, Min, sum{epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # big T constraints
    @constraint(m, pathTime[d=eachindex(tripData)],
        T[d] == sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])})
    # second order cone constraints (define epsilon), equal to time of first path
    @constraint(m, epsLower[d=eachindex(tripData)],
        norm([2 * sqrt(tripData[d].time), T[d] - epsilon[d]])
        <= sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} + epsilon[d]
        )
    @constraint(m, epsUpper[d=eachindex(tripData)],
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} <=
        epsilon[d] * tripData[d].time
        )

    # inequality constraints
    @constraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
        sum{paths[d][p+1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][p+1])} >=
        sum{paths[d][1][edge] * paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])}
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

    # SOLVE SOCP
    status = solve(m)
    times = getValue(t)

    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))
    for i in vertices(g), j in out_neighbors(g,i)
        result[i,j] = times[i,j]
    end

    return result
end
