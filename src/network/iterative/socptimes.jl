###################################################
## network/iterative/socptimes.jl
## SOCP that finds new traveltimes to optimize cost function
###################################################


"""
    socpTimes :
    optimize travel times to minimize L1 error from data with given paths
"""
function socpTimes(s::IterativeState; args...)
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips


    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = MosekSolver(MSK_DPAR_OPTIMIZER_MAX_TIME=10000.; args...))

    # DECISION VARIABLES
    # Road times
    @defVar(m, t[i=vertices(g), j=out_neighbors(g,i)] >= s.data.minTimes[i,j])
    # Absolute difference between tripData times and computed times
    @defVar(m, epsilon[d=eachindex(tripData)] >= 0)
    @defVar(m, T[d=eachindex(tripData)] >= 0)
    @defVar(m, fixedTime >= 0)

    # OBJECTIVE
    @setObjective(m, Min, sum{epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # big T constraints
    @addConstraint(m, pathTime[d=eachindex(tripData)],
        T[d] == sum{t[paths[d][1][i], paths[d][1][i+1]], i=1:(length(paths[d][1])-1)} + fixedTime)
    # second order cone constraints (define epsilon), equal to time of first path
    @addConstraint(m, epsLower[d=eachindex(tripData)],
        norm([2 * sqrt(tripData[d].time), T[d] - epsilon[d]])
        <= sum{t[paths[d][1][i], paths[d][1][i+1]], i=1:(length(paths[d][1])-1)} + fixedTime + epsilon[d]
        )
    @addConstraint(m, epsUpper[d=eachindex(tripData)],
        sum{t[paths[d][1][i], paths[d][1][i+1]], i=1:(length(paths[d][1])-1)} + fixedTime <=
        epsilon[d] * tripData[d].time
        )

    # inequality constraints
    @addConstraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
        sum{t[paths[d][p+1][i], paths[d][p+1][i+1]], i=1:(length(paths[d][p+1])-1)} >=
        sum{t[paths[d][1][i], paths[d][1][i+1]], i=1:(length(paths[d][1])-1)}
        )

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