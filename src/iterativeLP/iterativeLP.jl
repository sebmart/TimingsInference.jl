###################################################
## interativeLP.jl
## Iterates L1 error minimization on a network
###################################################

"""
    `doIteration` : compute iterations of the given iterative algorithm
    - `state`: state to iterate on, `n`: number of iterations
    - `method`: method to optimize traveltimes (default = "lp")
"""
function doIteration!(state::IterativeState, n::Int=1; method::AbstractString="lp")
    for k in 1:n
        #running the method and save the new times
        if method == "lp"
            times = lpTravelTimes(state)
        elseif method == "mip"
            times = mipTravelTimes(state)
        else
            error("method $method is not implemented")
        end
        #update the state with the new timings
        updateState!(state, times)

    end
    return state
end
