###################################################
## network/solvers/socp.jl
## SOCP that finds new traveltimes to optimize cost function
###################################################


"""
    socpTimes :
    optimize travel times to minimize L1 error from data with given paths

    `continuityConstraint` can be
    - "none" : no constraint
    - "simple": simple ϵ-based continuity
    - "neighborhoods": continuity constraint for each neighborhood
"""
function socpTimes(s::IterativeState;
                   inequalityConstraints::Bool = true,
                   continuityConstraint::AbstractString="none",
                   velocityBound::Float64 = 0.1,
                   args...)
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips
    roads = s.data.network.roads

    #Create the model (will be changed to avoid hard-coded parameters)
    # !BarConvTol needs to be changed
    m = Model(solver = MosekSolver(MSK_DPAR_OPTIMIZER_MAX_TIME=10000.,
                                   MSK_IPAR_INFEAS_REPORT_AUTO = MSK_ON; args...))

    # DECISION VARIABLES
    # Road times
    @variable(m, t[i=vertices(g), j=out_neighbors(g,i)] >= s.data.minTimes[i,j])
    # Absolute difference between tripData times and computed times
    @variable(m, epsilon[d=eachindex(tripData)] >= 0)
    @variable(m, T[d=eachindex(tripData)] >= 0)

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
    @objective(m, Min, sum{tripData[d].weight * epsilon[d], d=eachindex(tripData)})

    # CONSTRAINTS
    # big T constraints
    @constraint(m, pathTime[d=eachindex(tripData)],
        T[d] == sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])})
    # second order cone constraints (define epsilon), equal to time of first path
    @constraint(m, epsLower[d=eachindex(tripData)],
        norm([2 * sqrt(tripData[d].time), T[d] - epsilon[d]])
        <= sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} + epsilon[d]
        )
    @constraint(m, epsUpper[d=eachindex(tripData)],
        sum{paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])} <=
        epsilon[d] * tripData[d].time
        )

    # inequality constraints
    if inequalityConstraints
        @constraint(m, inequalityPath[d=eachindex(tripData), p=1:(length(paths[d])-1)],
            sum{paths[d][p+1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][p+1])} >=
            sum{paths[d][1][edge] * paths[d][1][edge] * t[src(edge), dst(edge)], edge=keys(paths[d][1])}
            )
    end
    if continuityConstraint == "simple"
        # continuity constraints
        for i in vertices(g), j in out_neighbors(g,i)
            for edge in findNearEdgesSameType(s.data.network, Edge(i,j))
                p = src(edge)
                q = dst(edge)
                @constraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                    <= velocityBound * (roads[i,j].distance + roads[p,q].distance) / 2)
                @constraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                    >= - velocityBound * (roads[i,j].distance + roads[p,q].distance) / 2)
            end
        end
    elseif continuityConstraint == "neighborhoods"
        # continuity constraints
        clusters = clusterEdges(s.data.network)
        for (k, cluster) in enumerate(clusters)
            for edge in cluster
                i=src(edge); j=dst(edge);
                for nearEdge in findNearEdgesSameType(s.data.network, edge)
                    p=src(nearEdge); q=dst(nearEdge);
                    @constraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                        <= velocity[(i,j,p,q)] * (roads[i,j].distance + roads[p,q].distance) / 2)
                    @constraint(m, t[i,j]/roads[i,j].distance - t[p,q]/roads[p,q].distance
                        >= - velocity[(i,j,p,q)] * (roads[i,j].distance + roads[p,q].distance) / 2)
                end
            end
            vList = flatten(
            [
                [
                    (src(edge), dst(edge), src(nearEdge), dst(nearEdge))
                     for nearEdge in findNearEdgesSameType(s.data.network, edge)
                ]
                 for edge in cluster
            ])
            @constraint(m, sum{velocity[(i,j,p,q)], (i,j,p,q) in vList} <= length(vList) * velocityBound)
        end
    end
    # SOLVE SOCP
    status = solve(m)
    # if infeasible, remove possible causes of infeasibility
    if status == :Infeasible && continuityConstraint=="none"
        return socpTimes(s, inequalityConstraints = false)
    end
    times = getvalue(t)

    # Export result as sparse matrix
    result = spzeros(Float64, nv(g), nv(g))
    for i in vertices(g), j in out_neighbors(g,i)
        result[i,j] = times[i,j]
    end

    return result
end
