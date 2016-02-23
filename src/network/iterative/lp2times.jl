###################################################
## network/iterative/lp2times.jl
## More advanced two-LP method for travel time inference
###################################################

"""
    `lp2Times`, optimize travel times to minimize L1 error from data with given paths
"""
function lp2Times(s::IterativeState; args...) #args is solver args
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips
    roads = s.data.network.roads

    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = GurobiSolver(TimeLimit=10000, Method=3, BarConvTol=1e-6; args...))

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
    objective = getObjectiveValue(m)

    # SET UP SECOND STEP
    # objective function variables
    @defVar(m, delta2[i=vertices(g), j=out_neighbors(g,i)] >= 0)

    # CONSTRAINTS
    # for objective
	@addConstraint(m, objConstrLower[i=vertices(g), j=out_neighbors(g,i)],
		-1 * t[i,j]/roads[i,j].distance + 1/(length(in_neighbors(g, i)) + length(out_neighbors(g,j))) * (sum{1/roads[j,k].distance * t[j,k], k = out_neighbors(g,j)} + sum{1/roads[h,i].distance * t[h,i], h=in_neighbors(g,i)}) <=
		delta2[i,j]
		)
	@addConstraint(m, objConstrUpper[i=vertices(g), j=out_neighbors(g,i)],
		t[i,j]/roads[i,j].distance - 1/(length(in_neighbors(g,i)) + length(out_neighbors(g,j))) * (sum{1/roads[j,k].distance * t[j,k], k = out_neighbors(g,j)} + sum{1/roads[h,i].distance * t[h,i], h=in_neighbors(g,i)}) <=
		delta2[i,j]
		)
	# fix objective from first step
	@addConstraint(m, fixObjective,
		sum{ sqrt(tripData[d].weight)*epsilon[d], d=eachindex(tripData)} <=
		1.02 * objective
		)

	# OBJECTIVE
	@setObjective(m, Min, sum{delta2[i,j], i=vertices(g), j=out_neighbors(g,i)})

	# SOLVE SECOND LP
	status = solve(m)
	times = getValue(t)

    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))
    for i in vertices(g), j in out_neighbors(g,i)
        result[i,j] = times[i,j]
    end

    return result
end
