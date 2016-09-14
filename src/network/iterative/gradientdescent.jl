###################################################
## network/iterative/gradientdescent.jl
## Stochastic gradient descent by batch
###################################################

"""
    `GradientDescent`, Iterative state optimizing on batchs of trips
"""
type GradientDescent <: IterativeState
    # inherited attributes
    data::NetworkData
    timings::NetworkTimings
    trips::Vector{NetworkTrip}
    # we do not use this one.
    paths::Vector{Vector{Dict{Edge, Float64}}}
    pathDiff::Float64

    "number of trips used at each iteration"
    batchSize::Int64
    "Default negative speed gradient, to counter-balance minimum-effect"
    defaultGrad::Float64
    "learning rate : step = firststep/n^alpha. Should be <1 and >1/2"
    alpha::Float64
    firstStep::Float64
    "Number of gradient steps per iteration"
    stepsPerIteration::Int64

    "iteration number"
    iter::Int64
    "step number"
    step::Int64

    function GradientDescent(data::NetworkData, startSolution::NetworkTimings; batchSize::Int = 1000, defaultGrad::Float64 = -1., alpha::Float64=0.6, firstStep::Float64=1., stepsPerIteration=1)
        gd = new()
        srand(1991)
        gd.trips = shuffle(data.trips)
        gd.timings = startSolution
        gd.data = data
        gd.pathDiff = Inf
        gd.paths = []


        gd.batchSize = batchSize
        gd.defaultGrad = defaultGrad
        gd.alpha = alpha
        gd.firstStep = firstStep
        gd.stepsPerIteration = stepsPerIteration

        gd.iter = 1
        gd.step = 1
        return gd
    end
end




GradientDescent(data::NetworkData, initTimes::AbstractArray{Float64, 2}; args...) =
    GradientDescent(data, NetworkTimings(data.network, initTimes); args...)


"""
    Update paths of LimitedPaths object given new times
"""
function updateState!(s::GradientDescent)
    # update the timings and compute shortest paths
    s.timings = NetworkTimings(s.data.network, times)
    newTimes = copy(s.timings.times)

    for i in 1:s.stepsPerIteration
        gradientStep!(s, newTimes)
        s.step +=1
    end
    s.iter += 1
end

"""
    Updates times with one step of batch gradient
"""
function gradientStep!(s::GradientDescent, currentTimes)
    gradient = Dict{Tuple{Int64, Int64}, Float64}()
    for (o,d) in keys(s.data.network.roads)
        gradient[o,d] = 0.
    end
    for i = 1:s.batchSize
        trip = s.data.trips[(i-1+(s.iter-1)*s.batchSize)%length(s.data.trips) + 1]
        tripEdges = getPathEdges(s.timings, trip.orig[1], trip.dest[1])

        tod = pathEdgesTime(currentTimes, tripEdges)

        grad = - sign(tod - trip.time) * trip.weight * 1/tod
        for e in getPathEdges(s.timings, trip.orig[1], trip.dest[1])
            gradient[src(e), dst(e)] += grad
        end
    end

    for ((o,d), g) in gradient
        if g == 0
            g = s.defaultGrad
        end
        currentTimes[o,d] = currentTimes[o,d] + gradient[o,d] * s.firstStep/(s.iter^s.alpha)
        (currentTimes[o,d] < s.data.minTimes[o,d]) && (currentTimes[o,d] = s.data.minTimes[o,d])
    end
    return
end
