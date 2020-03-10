###################################################
## network/solvers/roadtypespeed.jl
## A variation on the SOCP solver with a constant speed for each road-type
###################################################


"""
    constantSpeedSolver :
    optimize travel times to minimize SOCP error from data with given paths

    `uniqueSpeed` can be
    - false: one speed per roadType
    - true : one speed for everyone
"""
function constantSpeedSolver(s::IterativeState; uniqueSpeed::Bool = false, args...)
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips
    roads = s.data.network.roads

    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = MosekSolver(MSK_DPAR_OPTIMIZER_MAX_TIME=10000.; args...))

    # DECISION VARIABLES
    # inversed Road-type speeds times
    @variable(m, s[r=1:6] >= 0)

    # Absolute difference between tripData times and computed times
    @variable(m, maxRatioError[d=eachindex(tripData)] >= 0)
    @variable(m, T[d=eachindex(tripData)] >= 0)

    # OBJECTIVE
    @objective(m, Min, sum(tripData[d].weight * maxRatioError[d] for d in eachindex(tripData)))

    # CONSTRAINTS
    # big T constraints
    @constraint(m, pathTime[d=eachindex(tripData)],
        T[d] == sum(paths[d][1][edge] * s[roads[src(edge), dst(edge)].roadType] * roads[src(edge), dst(edge)].distance for edge in keys(paths[d][1])))

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
