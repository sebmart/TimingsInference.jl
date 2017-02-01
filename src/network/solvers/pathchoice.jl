###################################################
## network/solvers/pathchoice.jl
## Model that incorporates path choice
###################################################


"""
    pathChoice :
    optimize travel times to minimize error from data with given paths
    Model from Zhan et al.
"""
function pathChoice(s::IterativeState; args...)
    g = s.data.network.graph
    paths = s.paths
    tripData = s.trips
    roads = s.data.network.roads

    const beta1 = 0.275 / 60.
    const beta2 = 1.563 / 1609.344

    const MAX_SPEED = 30 * 1609.344 / 3600
    const MIN_SPEED = 1 * 1609.344 / 3600

    lambda = 1e2
    const DROP = 0.1
    const BOOST = 10.
    const MAX_LAMBDA = 1e16
    const MIN_LAMBDA = 1e-16

    oldObjective = 0
    objective = 1e16

    # current times of edges
    t = s.timings.times
    theta = 1.
    # length of each path
    d = zeros(length(tripData), s.pathsPerTrip)
    for i in eachindex(tripData), j = 1:s.pathsPerTrip
        @inbounds d[i,j] = sum(paths[i][j][edge] * roads[src(edge), dst(edge)].distance 
                               for edge=keys(paths[i][j]))
    end
    # time of each path
    g = zeros(length(tripData), s.pathsPerTrip)
    # probability of each path
    p = zeros(length(tripData), s.pathsPerTrip)
    # normalizing factor
    S = zeros(length(tripData))
    # residuals
    r = zeros(length(tripData))
    # put all the path/probability/objective calculations in a method
    function calculate!()
        for i in eachindex(tripData), j = 1:s.pathsPerTrip
            @inbounds g[i,j] = sum(paths[i][j][edge] * t[src(edge), dst(edge)]
                                   for edge=keys(paths[i][j]))
        end
        p = exp(theta .* (-beta1 .* g - beta2 .* d))
        # normalizing factor
        S = sum(p, 2)
        @simd for i = eachindex(tripData)
            @inbounds r[i] = tripData[i].time - dot(p[i,:], g[i,:])/S[i]
        end
    end
    # perform these calculations
    calculate!()
    # derivative of normalizing factor
    dSdt = zeros(length(tripData), length(roads) + 1)
    # derivative matrix
    J = zeros(length(tripData), length(roads) + 1)


    while abs(oldObjective - objective) > 1e-6 * oldObjective
        oldObjective = objective
        # derivative of normalizing factor
        for i in eachindex(tripData)
            for (k, (src, dst)) in enumerate(keys(roads))
                @inbounds dSdt[i,k] = -beta1 * sum(p[i,m] * get(paths[i][m], Edge(src, dst), 0) 
                                         for m = 1:s.pathsPerTrip)
            end
            dSdt[i,end] = - dot(p[i,:], beta1 * g[i,:] + beta2 * d[i,:])
        end
        # derivative matrix
        for i = eachindex(tripData)
            for (k, (src, dst)) in enumerate(keys(roads))
                @inbounds J[i,k] = 1/S[i] ^ 2 * sum(
                                          [(p[i,m] * S[i] * get(paths[i][m], Edge(src, dst), 0) 
                                            * (1 - beta1 * theta * g[i,m])) for m=1:s.pathsPerTrip] 
                                          - g[i,:] .* p[i,:] * dSdt[i,k]
                                          )
            end
            J[i,end] = - dot(p[i,:] .* g[i,:]/S[i], 
                             beta1 * g[i,:] + beta2 * d[i,:] + dSdt[i,end]/S[i])
        end
        diagTerms = vec(sumabs2(J,1))
        @simd for i in eachindex(diagTerms)
            @inbounds if diagTerms[i] < 1e-6
                diagTerms[i] = 1e-6
            end
        end
        println("*** Solving LM ***")
        while true
            # solve Levenberg-Marquardt system
            updateDir = (J'*J + lambda * diagm(diagTerms)) \ (J'*r)
            # save old parameters
            oldTheta = theta
            oldTimes = copy(t)
            # update parameters
            for (k, (src, dst)) in enumerate(keys(roads))
                t[src, dst] += updateDir[k]
                if t[src, dst] < roads[src, dst].distance/MAX_SPEED
                    t[src, dst] = roads[src, dst].distance/MAX_SPEED
                elseif t[src,dst] > roads[src, dst].distance/MIN_SPEED
                    t[src, dst] = roads[src, dst].distance/MIN_SPEED
                end
            end
            theta += updateDir[end]
            # see what things looklike now
            calculate!()
            objective = sumabs2(r)
            # check if we made progress
            println("λ = ", lambda)
            println("Old objective: ", oldObjective)
            println("New objective: ", objective)
            if objective <= oldObjective
                if lambda < MAX_LAMBDA && abs(objective - oldObjective) < 1e-3 * oldObjective
                    println("Reselecting lambda")
                    lambda = min(lambda * BOOST, MAX_LAMBDA) # need steeper descent
                    # reset parameters
                    t = oldTimes
                    theta = oldTheta
                    calculate!()
                else
                    if abs(objective - oldObjective) > 1e-2 * oldObjective
                        # can decrease lambda: fast convergence
                        lambda = max(lambda * DROP, MIN_LAMBDA)
                    end
                    break
                end
            else
                println("Reselecting lambda")
                if lambda < MAX_LAMBDA
                    lambda = lambda * BOOST # need steeper descent
                else
                    break
                end
                # reset parameters
                t = oldTimes
                theta = oldTheta
                calculate!()
            end
        end
    end
    println("θ = $(theta)")
    return t
end
