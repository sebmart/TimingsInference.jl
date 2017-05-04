###################################################
## comparetimes.jl
## Add the possibility to compare several timings situations
###################################################

"""
    `CompareTimes`: Network visualizer that compares a set of road times to a given baseline
    `SPACE` and `B` to move through visualizations
    If given NetworkTimings, triggers path visualization.
"""
type CompareTimes <: NetworkVisualizer
    # Mandatory attributes
    network::Network
    window::RenderWindow
    view::View
    nodes::Vector{CircleShape}
    roads::Dict{Tuple{Int,Int},Line}
    nodeRadius::Float64
    colors::VizColors

    "the underlying visualizer"
    viz::NetworkVisualizer
    "list of times to show"
    times::Vector{AbstractArray{Float64,2}}
    "routing information"
    routing::Vector{NetworkTimings}
    "current times to show"
    currentTime::Int
    "if we use a routing visualizer"
    withrouting::Bool

    "contructor"
    function CompareTimes(n::Network,
                          times::Vector{AbstractArray{Float64,2}},
                          routing::Vector{NetworkTimings}=NetworkTimings[];
                          colors::RoutingColors=SpeedColors(n, times[1]),
                          computePaths::Bool = false)
        if length(times) == 0
            error("Need at least one set of road times")
        end
        obj = new()
        obj.network  = n
        obj.times = times
        obj.routing = routing
        obj.colors = colors
        if computePaths && isempty(obj.routing)
            obj.routing = NetworkTimings[NetworkTimings(n, t) for t in times]
        end
        return obj
    end
end

CompareTimes{T<:NetworkStats}(n::Network, stats::Vector{T}; args...) =
CompareTimes(n, AbstractArray{Float64,2}[s.times for s in stats]; args...)

CompareTimes(n::Network, routing::Vector{NetworkTimings}; args...) =
CompareTimes(n, AbstractArray{Float64,2}[r.times for r in routing], routing; args...)

function visualInit(v::CompareTimes)
    v.withrouting = (length(v.routing) == length(v.times))

    if v.withrouting
        v.viz = RoutingViz(v.routing[1], colors=v.colors)
    else
        v.viz = NetworkViz(v.network, colors=v.colors)
    end
    v.currentTime = 1
    v.colors.roadtimes = v.times[v.currentTime]
    copyVisualData(v,v.viz)
    visualInit(v.viz)
end

visualStartUpdate(v::CompareTimes, frameTime::Float64) = visualStartUpdate(v.viz, frameTime)

visualEndUpdate(v::CompareTimes, frameTime::Float64) = visualEndUpdate(v.viz, frameTime)

visualRedraw(v::CompareTimes) = visualRedraw(v.viz)


function visualEvent(v::CompareTimes, event::Event)
    if get_type(event) == EventType.KEY_PRESSED && get_key(event).key_code == KeyCode.SPACE
        #move forward
        if v.currentTime < length(v.times)
            v.currentTime += 1
            if v.withrouting
                v.viz.routing = v.routing[v.currentTime]
            end
            v.colors.roadtimes = v.times[v.currentTime]
            redraw!(v)
        end
    elseif get_type(event) == EventType.KEY_PRESSED && get_key(event).key_code == KeyCode.B
        #move backward
        if v.currentTime > 1
            v.currentTime -= 1
            if v.withrouting
                v.viz.routing = v.routing[v.currentTime]
            end
            v.colors.roadtimes = v.times[v.currentTime]
            redraw!(v)
        end
    else
        visualEvent(v.viz, event)
    end
end
