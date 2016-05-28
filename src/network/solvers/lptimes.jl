###################################################
## network/solvers/lptimes.jl
## Simple LP method for travel time inference
###################################################

"""
    `lpTimes`, optimize travel times to minimize L1 error from data with given paths
"""
function lpTimes(s::IterativeState; args...) #args is solver args
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
    @defVar(m, fixedTime >= 0)

    # OBJECTIVE
    @setObjective(m, Min, sum{ sqrt(tripData[d].weight/tripData[d].time)*epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # absolute values contraints (define epsilon), equal to time of first path
    @addConstraint(m, epsLower[d=eachindex(tripData)],
        sum{t[src(paths[d][1][i]), dst(paths[d][1][i])], i=eachindex(paths[d][1])} + fixedTime - tripData[d].time >=
        - epsilon[d])
    @addConstraint(m, epsUpper[d=eachindex(tripData)],
        sum{t[src(paths[d][1][i]), dst(paths[d][1][i])], i=eachindex(paths[d][1])} + fixedTime - tripData[d].time <=
        epsilon[d])

    # inequality constraints
    @addConstraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
        sum{t[src(paths[d][p+1][i]), dst(paths[d][p+1][i])], i=eachindex(paths[d][p+1])} >=
        sum{t[src(paths[d][1][i]), dst(paths[d][1][i])], i=eachindex(paths[d][1])}
        )

    # SOLVE LP
    status = solve(m)
    times = getValue(t)
    fixedTime = max(getValue(fixedTime), 0.)

    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))
    for i in vertices(g), j in out_neighbors(g,i)
        result[i,j] = times[i,j]
    end

    return result, fixedTime
end
