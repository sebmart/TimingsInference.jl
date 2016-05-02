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

    edgeList = sort(collect(keys(roads)))
    srand(1992)
    independent, dependent = pickIndepEdges(0.1, s.data.network)
    dep, emap = findNetworkDependence(s.data.network, independent, dependent)
    simplifiedPaths = [[simplifyPath(paths[d][i], dep, emap) for i = 1:length(paths[d])] for d = eachindex(tripData)]

    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = GurobiSolver(TimeLimit=10000, Crossover=0, Method=3, BarConvTol=1e-6; args...))

    # DECISION VARIABLES
    # Road times
    @defVar(m, t[i=eachindex(independent)] >= s.data.minTimes[edgeList[independent[i]][1], edgeList[independent[i]][2]])
    # Absolute difference between tripData times and computed times
    @defVar(m, epsilon[d=eachindex(tripData)] >= 0)

    # OBJECTIVE
    @setObjective(m, Min, sum{ sqrt(tripData[d].weight/tripData[d].time)*epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # absolute values contraints (define epsilon), equal to time of first path
    @addConstraint(m, epsLower[d=eachindex(tripData)],
        sum{t[i] * simplifiedPaths[d][1][i], i=eachindex(independent)} - tripData[d].time >=
        - epsilon[d]
        )
    @addConstraint(m, epsUpper[d=eachindex(tripData)],
        sum{t[i] * simplifiedPaths[d][1][i], i=eachindex(independent)} - tripData[d].time <=
        epsilon[d]
        )

    # inequality constraints
    @addConstraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
        sum{t[i] * simplifiedPaths[d][p+1][i], i=eachindex(independent)} >=
        sum{t[i] * simplifiedPaths[d][1][i], i=eachindex(independent)}
        )

    # SOLVE LP
    status = solve(m)
    if status == :Infeasible
        buildInternalModel(m)
        print_iis_gurobi(m)
    end
    times = getValue(t)

    timesArray = [times[i] for i=eachindex(independent)]
    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))
    for i in vertices(g), j in out_neighbors(g,i)
        result[i,j] = evaluateTime(dep[:,emap[(i,j)]], timesArray)
    end

    return result
end
