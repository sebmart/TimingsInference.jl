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

    beta1 = 0.275 / 60.
    beta2 = 1.563 / 1609.344
    lambda = 0.1
    DROP = 0.01
    BOOST = 10.
    oldObjective = 0
    objective = Inf

    # current times of edges
    t = s.timings.times
    theta = 1.
    # length of each path
    d = zeros(length(tripData), s.pathsPerTrip)
    for i in eachindex(tripData), j = 1:s.pathsPerTrip
        @inbounds d[i,j] = sum([paths[i][j][edge] * roads[src(edge), dst(edge)].distance 
                               for edge=keys(paths[i][j])])
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
            @inbounds g[i,j] = sum([paths[i][j][edge] * t[src(edge), dst(edge)]
                                   for edge=keys(paths[i][j])])
        end
        p = exp(theta .* (-beta1 .* g - beta2 .* d))
        # normalizing factor
        S = sum(p, 2)
        for i = eachindex(tripData)
            r[i] = tripData[i].time - dot(p[i,:], g[i,:])/S[i]
        end
    end
    # perform these calculations
    calculate!()
    # derivative of normalizing factor
    dSdt = zeros(length(tripData), length(roads) + 1)
    # derivative matrix
    J = zeros(length(tripData), length(roads) + 1)


    while abs(oldObjective - objective) > 1e-1
        oldObjective = objective
        # derivative of normalizing factor
        for i in eachindex(tripData)
            for (j, (src, dst)) in enumerate(keys(roads))
                dSdt[i,j] = -beta1 * sum([p[i,m] * get(paths[i][m], Edge(src, dst), 0) 
                                         for m = 1:s.pathsPerTrip])
            end
            dSdt[i,end] = - dot(p[i,:], beta1 * g[i,:] + beta2 * d[i,:])
        end
        # derivative matrix
        for i = eachindex(tripData)
            for (k, (src, dst)) in enumerate(keys(roads))
                J[i,k] = 1/S[i] ^ 2 * sum(
                                          [(p[i,m] * S[i] * get(paths[i][m], Edge(src, dst), 0) 
                                            * (1 - beta1 * theta * g[i,m])) for m=1:s.pathsPerTrip] 
                                          + g[i,:] .* p[i,:] * dSdt[i,k]
                                          )
            end
            J[i,end] = dot(p[i,:], beta1 * g[i,:] + beta2 * d[i,:] + dSdt[i,end]/S[i])
        end
        println("Solving LM")
        while true
            # solve Levenberg-Marquardt system
            diagTerms = vec(sumabs2(J,1))
            for i in eachindex(diagTerms)
                if diagTerms[i] < 1e-6
                    diagTerms[i] = 1e-6
                end
            end
            updateDir = (J'*J + lambda * diagm(vec(sumabs2(J,1)))) \ (J'*r)
            println(J'*r)
            sleep(1)
            # update parameters
            for (k, (src, dst)) in enumerate(keys(roads))
                t[src, dst] += updateDir[k]
            end
            theta += updateDir[end]
            # see what things looklike now
            calculate!()
            objective = sumabs2(r)
            # check if we made progress
            println("Old objective: ", oldObjective)
            println("New objective: ", objective)
            if objective < oldObjective
                lambda = lambda * DROP      # can decrease lambda for faster convergence
                break
            else
                println("Reselecting lambda")
                lambda = lambda * BOOST     # need steeper descent
            end
            break
        end
        break
    end
    println("θ = ", theta)
    return t
end
