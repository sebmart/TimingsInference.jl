###################################################
## network/solvers/roadtypespeed.jl
## A variation on the SOCP solver with a constant speed for each road-type
###################################################


"""
    socpTimes :
    optimize travel times to minimize L1 error from data with given paths

    `continuityConstraint` can be
    - "none" : no constraint
    - "simple": simple ϵ-based continuity
    - "neighborhoods": continuity constraint for each neighborhood
"""
function constantSpeedTimes(s::IterativeState; args...)
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips
    roads = s.data.network.roads

    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = MosekSolver(MSK_DPAR_OPTIMIZER_MAX_TIME=10000.,
                                   MSK_IPAR_INFEAS_REPORT_AUTO = MSK_ON; args...))

    # DECISION VARIABLES
    # inversed Road-type speeds times
    @variable(m, s[r=1:6] >= 0)

    # Absolute difference between tripData times and computed times
    @variable(m, maxRatioError[d=eachindex(tripData)] >= 0)
    @variable(m, T[d=eachindex(tripData)] >= 0)

    # OBJECTIVE
    @objective(m, Min, sum{tripData[d].weight * maxRatioError[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # big T constraints
    @constraint(m, pathTime[d=eachindex(tripData)],
        T[d] == sum{paths[d][1][edge] * s[roads[src(edge), dst(edge)].roadType] * roads[src(edge), dst(edge)].distance, edge=keys(paths[d][1])})

    # second order cone constraints (define epsilon), equal to time of first path
    @constraint(m, errorLower[d=eachindex(tripData)],
        norm([2 * sqrt(tripData[d].time), T[d] - maxRatioError[d]])
        <= T[d] + maxRatioError[d]
        )
    @constraint(m, errorUpper[d=eachindex(tripData)],
        T[d] <= maxRatioError[d] * tripData[d].time
        )

    # SOLVE SOCP
    status = solve(m)

    invSpeeds = getvalue(s)

    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))
    for i in vertices(g), j in out_neighbors(g,i)
        result[i,j] = invSpeeds[roads[i ,j].roadType] * roads[i, j].distance
    end

    return result
end
