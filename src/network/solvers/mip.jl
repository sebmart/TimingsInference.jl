###################################################
## network/solvers/mip.jl
## MIP to select minimums
###################################################


"""
    `mipTimes` : optimize travel times to minimize L1 error from data with given paths
"""
function mipTimes(s::IterativeState, args...)
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips

    # Big M = max time of paths -- right now: 5km/h speed
    minTimes = uniformTimes(s.data.network, 5.)
    M = Float64[maximum([pathTime(minTimes,p) for p in l]) for l in paths]


    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = GurobiSolver(TimeLimit=10000, OutputFlag=1, Method=3, BarConvTol=1e-6; args...))

    # DECISION VARIABLES
    # Road times
    @defVar(m, t[i=vertices(g), j=out_neighbors(g,i)] >= s.data.minTimes[i,j])
    # Absolute difference between tripData times and computed times
    @defVar(m, epsilon[d=eachindex(tripData)] >= 0)
    # Time of the trips
    @defVar(m, T[d=eachindex(tripData)] >= 0)
    # Integer variables to decide which path is the shortest
    @defVar(m, minP[d=eachindex(tripData),p=1:length(paths[d])], Bin)


    # OBJECTIVE
    @setObjective(m, Min, sum{ sqrt(tripData[d].weight/tripData[d].time)*epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # absolute values contraints (define epsilon), equal to time of first path
    @addConstraint(m, epsLower[d=eachindex(tripData)], T[d] - tripData[d].time >= - epsilon[d])
    @addConstraint(m, epsUpper[d=eachindex(tripData)], T[d] - tripData[d].time <=   epsilon[d])

    # inequality constraints
    @addConstraint(m, inequalityPath[d=eachindex(tripData), p=eachindex(paths[d])],
        sum{paths[d][p][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][p])} >= T[d] )

    # "minimum equality" contraints
    @addConstraint(m, equalityPath[d=eachindex(tripData), p=eachindex(paths[d])],
        sum{paths[d][p][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][p])} - M[d]*(1 - minP[d,p]) <= T[d])

    # integer constraints
    @addConstraint(m, equalityPath[d=eachindex(tripData)], sum{minP[d,p], p = eachindex(paths[d])} == 1)

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
