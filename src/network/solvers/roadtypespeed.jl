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
function constantSpeedSolver(s::IterativeState; uniqueSpeed::Bool = false, args...)
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

    if uniqueSpeed
        @constraint(m, equalSpeeds[i=2:6], s[i] == s[1])
    end

    # SOLVE SOCP
    status = solve(m)

    invSpeeds = getvalue(s)

    return Float64[1/iSp for iSp in invSpeeds]
end

function constantSpeedTimes(s::IterativeState; uniqueSpeed::Bool = false, args...)
    # Export result as sparse matrix
    speeds = constantSpeedSolver(s, uniqueSpeed=uniqueSpeed; args...)
    result = spzeros(Float64, nv(s.data.network.graph), nv(s.data.network.graph))
    for i in vertices(s.data.network.graph), j in out_neighbors(s.data.network.graph,i)
        result[i,j] = s.data.network.roads[i, j].distance / speeds[s.data.network.roads[i ,j].roadType]
    end
    return result
end
