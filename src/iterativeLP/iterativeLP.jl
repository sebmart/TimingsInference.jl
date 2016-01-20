###################################################
## interativeLP.jl
## Iterates L1 error minimization on a network
###################################################

"""
    `doIteration` : compute iterations of the given iterative algorithm
    - `state`: state to iterate on, `n`: number of iterations
"""
function doIteration!(state::IterativeState, n::Int=1)
    for k in 1:n
        #running the LP and save the new times
        times = lpTravelTimes(state)

        #update the state with the new timings
        updateState!(state, times)

    end
    return state
end
