###################################################
## network/solvers/fraclp.jl
## Fractional LP (symmetric cost function) that finds new traveltimes
###################################################


"""
    fraclpTimes :
    optimize travel times to minimize L1 error from data with given paths
"""
function fraclpTimes(s::IterativeState; args...)
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips


    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = GurobiSolver(TimeLimit=10000, Crossover=0, Method=2, NumericFocus=3, ScaleFlag=0))#Crossover=0, Method=3, BarConvTol=1e-6; args...))

    # DECISION VARIABLES
    # Road times
    @defVar(m, t[i=vertices(g), j=out_neighbors(g,i)] >= 0)
    # Absolute difference between tripData times and computed times
    @defVar(m, epsilon[d=eachindex(tripData)] >= 0)
    @defVar(m, y >= 0)

    # OBJECTIVE
    @setObjective(m, Min, sum{tripData[d].weight * epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # absolute values contraints (define epsilon), equal to time of first path
    @addConstraint(m, epsLower[d=eachindex(tripData)],
        epsilon[d] >=
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} - y * tripData[d].time
        )
    @addConstraint(m, epsUpper[d=eachindex(tripData)],
        epsilon[d] >= 
        - sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} + y * tripData[d].time
        )

    # inequality constraints
    @addConstraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
        sum{paths[d][p+1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][p+1])} >=
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])}
        )

    # fractional programming constraint
    @addConstraint(m, fracProgram,
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], d=eachindex(tripData), edge=keys(paths[d][1])}
        + y * sum([tripData[d].time for d=eachindex(tripData)]) == 1
        )

    # new bounds on edge velocities
    @addConstraint(m, speedLimits[i=vertices(g), j=out_neighbors(g,i)],
        t[i,j] >= s.data.minTimes[i,j] * y)

    # SOLVE LP
    status = solve(m)
    if status == :Infeasible
        buildInternalModel(m)
        print_iis_gurobi(m)
    end
    times = getValue(t)
    yVal = getValue(y)

    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))
    for i in vertices(g), j in out_neighbors(g,i)
        result[i,j] = times[i,j] / yVal
    end

    return result
end
