###################################################
## firstlp.jl
## MIP that finds new traveltimes to optimize cost function
###################################################


"""
    lpTravelTimes :
    optimize travel times to minimize L1 error from data with given paths
"""
function lpTravelTimes(s::IterativeState)
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips


    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = GurobiSolver(TimeLimit=10000, OutputFlag=1, Method=3, BarConvTol=1e-6))

    # DECISION VARIABLES
    # Road times
    @defVar(m, t[i=vertices(g), j=out_neighbors(g,i)] >= s.data.minTimes[i,j])
    # Absolute difference between tripData times and computed times
    @defVar(m, epsilon[d=eachindex(tripData)] >= 0)

    # OBJECTIVE
    @setObjective(m, Min, sum{ sqrt(tripData[d].count)*epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # absolute values contraints (define epsilon), equal to time of first path
    @addConstraint(m, epsLower[d=eachindex(tripData)],
        sum{t[paths[d][1][i], paths[d][1][i+1]], i=1:(length(paths[d][1])-1)} - tripData[d].time >=
        - epsilon[d])
    @addConstraint(m, epsUpper[d=eachindex(tripData)],
        sum{t[paths[d][1][i], paths[d][1][i+1]], i=1:(length(paths[d][1])-1)} - tripData[d].time <=
        epsilon[d])

    # inequality constraints
    @addConstraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
        sum{t[paths[d][p+1][i], paths[d][p+1][i+1]], i=1:(length(paths[d][p+1])-1)} >=
        sum{t[paths[d][1][i], paths[d][1][i+1]], i=1:(length(paths[d][1])-1)}
        )

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
