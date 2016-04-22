###################################################
## network/iterative/lptimes.jl
## LP that finds new traveltimes to optimize cost function
###################################################


"""
    lpTimes :
    optimize travel times to minimize L1 error from data with given paths
"""
function redlpTimes(s::IterativeState; args...)
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips
    roads = s.data.network.roads

    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = GurobiSolver(TimeLimit=10000, Crossover=0, Method=3, BarConvTol=1e-6; args...))

    # DECISION VARIABLES
    # Road times
    @defVar(m, t[i=vertices(g), j=out_neighbors(g,i)] >= s.data.minTimes[i,j])
    # Absolute difference between tripData times and computed times
    @defVar(m, epsilon[d=eachindex(tripData)] >= 0)

    # OBJECTIVE
    @setObjective(m, Min, sum{ sqrt(tripData[d].weight/tripData[d].time)*epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # change path representation
    srand(1992)
    independent = random2DBits(0.1, nNodes(s.data.network))
    dep = findNetworkDependence(s.data.network, independent, 10000)
    simplifiedPaths = [[simplifyPath(paths[d][i]) for i = 1:length(paths[d])] for d = eachindex(tripData)]

    # absolute values contraints (define epsilon), equal to time of first path
    @addConstraint(m, epsLower[d=eachindex(tripData)],
        sum{t[i,j] * simplifiedPaths[(i,j)], (i,j)=keys(simplifiedPaths[d][1])} - tripData[d].time >=
        - epsilon[d])
    @addConstraint(m, epsUpper[d=eachindex(tripData)],
        sum{t[i,j] * simplifiedPaths[(i,j)], (i,j)=keys(simplifiedPaths[d][1])} - tripData[d].time <=
        epsilon[d])

    # inequality constraints
    @addConstraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
        sum{t[i,j] * simplifiedPaths[(i,j)], (i,j)=keys(simplifiedPaths[d][p+1])} >=
        sum{t[i,j] * simplifiedPaths[(i,j)], (i,j)=keys(simplifiedPaths[d][1])}
        )

    # SOLVE LP
    status = solve(m)
    times = getValue(t)

    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))
    for i in vertices(g), j in out_neighbors(g,i)
        if independent[i,j]
            result[i,j] = times[i,j]
        end
    end
    for i in vertices(g), j in out_neighbors(g,i)
        if !independent[i,j]
            result[i,j] = evaluateTime(dep[(i,j)], result)
        end
    end

    return result
end
