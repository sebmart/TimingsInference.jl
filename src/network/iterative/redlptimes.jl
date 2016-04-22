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

    if isfile("/home/semartin/Tests/dep.jld")
        dep = load("/home/semartin/Tests/dep.jld", "dep")
        edges = load("/home/semartin/Tests/dep.jld", "edges")
        independent = load("/home/semartin/Tests/dep.jld", "independent")
    else
        srand(1992)
        independent = random2DBits(0.1, nNodes(s.data.network))
        dep, edges = findNetworkDependence(s.data.network, independent, 10000)
        save("/home/semartin/Tests/dep.jld", "dep", dep, "edges", edges, "independent", independent)
    end    
    simplifiedPaths = [[simplifyPath(paths[d][i]) for i = 1:length(paths[d])] for d = eachindex(tripData)]

    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = GurobiSolver(TimeLimit=10000, Crossover=0, Method=3, BarConvTol=1e-6; args...))

    # DECISION VARIABLES
    # Road times
    @defVar(m, t[i=eachindex(edges)] >= s.data.minTimes[edges[i][1], edges[i][2]])
    # Absolute difference between tripData times and computed times
    @defVar(m, epsilon[d=eachindex(tripData)] >= 0)

    # OBJECTIVE
    @setObjective(m, Min, sum{ sqrt(tripData[d].weight/tripData[d].time)*epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # absolute values contraints (define epsilon), equal to time of first path
    @addConstraint(m, epsLower[d=eachindex(tripData)],
        sum{t[i] * simplifiedPaths[d][1][i], i=eachindex(edges)} - tripData[d].time >=
        - epsilon[d]
        )
    @addConstraint(m, epsUpper[d=eachindex(tripData)],
        sum{t[i] * simplifiedPaths[d][1][i], i=eachindex(edges)} - tripData[d].time <=
        epsilon[d]
        )

    # inequality constraints
    @addConstraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
        sum{t[i] * simplifiedPaths[d][p+1][i], i=eachindex(edges)} >=
        sum{t[i] * simplifiedPaths[d][1][i], i=eachindex(edges)}
        )

    # SOLVE LP
    status = solve(m)
    times = getValue(t)

    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))
    for i in vertices(g), j in out_neighbors(g,i)
        result[i,j] = evaluateTime(dep[(i,j)], result)
    end

    return result
end
