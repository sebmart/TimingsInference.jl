###################################################
## interativeLP.jl
## Iterates L1 error minimization on a network
###################################################

"""
    `iterativeLP`
    - `state`: state to iterate on, `n`: number of iterations
"""
function iterativeLP!(state::IterativeState, n::Int)
    for k in 1:n
        #running the LP and save the new times
        times = lpTravelTimes(state)

        #update the state with the new timings
        updateState!(state, times)

    end
    return state
end
