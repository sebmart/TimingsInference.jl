###################################################
## network/solvers/lp.jl
## Simple LP method for travel time inference
###################################################

"""
    `lpTimes`, optimize travel times to minimize MAPE error

    `continuityConstraint` can be
    - "none" : no constraint
    - "simple": simple ϵ-based continuity
    - "neighborhoods": continuity constraint for each neighborhood
"""
function lpTimes(s::IterativeState;
                 continuityConstraint::AbstractString="none",
                 velocityBound::Float64 = 0.1, args...) #args is solver args
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips
    roads = s.data.network.roads

    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = GurobiSolver(TimeLimit=10000,
                                    Crossover = 0,
                                    Method=2,
                                    BarConvTol=1e-8; args...))

    # DECISION VARIABLES
    # Road times
    @variable(m, t[i=vertices(g), j=out_neighbors(g,i)] >= s.data.minTimes[i,j])
    # Absolute difference between tripData times and computed times
    @variable(m, epsilon[d=eachindex(tripData)] >= 0)

    if continuityConstraint == "neighborhoods"
        edgesAndNeighbors = flatten(
        [
            [
                (src(edge), dst(edge), src(nearEdge), dst(nearEdge))
                 for nearEdge in findNearEdgesSameType(s.data.network, edge)
            ]
         for edge in edges(g)
        ])
        @variable(m, velocity[(i,j,p,q) = edgesAndNeighbors] >= 0)
    end

    # OBJECTIVE
    @objective(m, Min, sum{ tripData[d].weight/tripData[d].time * epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # absolute values contraints (define epsilon), equal to time of first path
    @constraint(m, epsLower[d=eachindex(tripData)],
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} - tripData[d].time >=
        - epsilon[d])
    @constraint(m, epsUpper[d=eachindex(tripData)],
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} - tripData[d].time <=
        epsilon[d])

    # inequality constraints
    @constraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
        sum{paths[d][p+1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][p+1])} >=
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])}
        )

    if continuityConstraint == "simple"
        for i in vertices(g), j in out_neighbors(g,i)
            for edge in findNearEdgesSameType(s.data.network, Edge(i,j))
                p = src(edge)
                q = dst(edge)
                @constraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                    <= velocityBound)
                @constraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                    >= -velocityBound)
            end
        end
    elseif continuityConstraint == "neighborhoods"
        clusters = clusterEdges(s.data.network)
        for (k, cluster) in enumerate(clusters)
            println(k)
            for edge in cluster
                i=src(edge); j=dst(edge);
                for nearEdge in findNearEdgesSameType(s.data.network, edge)
                    p=src(nearEdge); q=dst(nearEdge);
                    @constraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                        <= velocity[(i,j,p,q)])
                    @constraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                        >= -velocity[(i,j,p,q)])
                end
            end
            vList = flatten([[(src(edge), dst(edge), src(nearEdge), dst(nearEdge)) for nearEdge in findNearEdgesSameType(s.data.network, edge)] for edge in cluster])
            @constraint(m, sum{velocity[(i,j,p,q)], (i,j,p,q) in vList} <= length(vList) * velocityBound)
        end
    end

    # SOLVE LP
    status = solve(m)
    times = getvalue(t)

    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))
    for i in vertices(g), j in out_neighbors(g,i)
        result[i,j] = times[i,j]
    end

    return result
end
