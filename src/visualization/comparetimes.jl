###################################################
## showtimes.jl
## Compare a set of road times to a reference one.
###################################################

"""
    `CompareTimes`: Network visualizer that compares a set of road times to a given baseline
"""
type CompareTimes <: NetworkVisualizer
    # Mandatory attributes
    network::Network
    window::RenderWindow
    nodes::Vector{CircleShape}
    roads::Dict{Tuple{Int,Int},Line}
    nodeRadius::Float64
    nodesToView::Vector{Node}


    "list of times to show"
    newtimes::Vector{AbstractArray{Float64,2}}
    "current times values"
    basetimes::AbstractArray{Float64,2}
    "current times to show"
    currentTime::Int
    "color palette"
    palette::Vector{Colors.RGB{Float64}}
    "ratio to baseline corresponding to extremes of color palette"
    maxRatio::Float64

    "contructor"
    function CompareTimes(n::Network, newtimes::Vector{AbstractArray{Float64,2}}, basetimes; maxRatio::Float64=3.)
        if length(newtimes) == 0
            error("Need at least one set of road times")
        end
        obj = new()
        obj.network  = n
        obj.nodesToView = n.nodes

        obj.newtimes = newtimes
        obj.basetimes = basetimes
        obj.maxRatio = maxRatio
        obj.palette = Colors.colormap("Reds")
        obj.currentTime = 1
        return obj
    end
end

CompareTimes(n::Network,time::AbstractArray{Float64,2}, basetimes; args...) =
CompareTimes(n,AbstractArray{Float64,2}[time], basetimes; args...)

CompareTimes(n::Network,timing::NetworkTimings, basetimes; args...) =
CompareTimes(n, AbstractArray{Float64,2}[timing.times], basetimes; args...)

CompareTimes(n::Network,stats::NetworkStats, basetimes; args...) =
CompareTimes(n, stats.times, basetimes; args...)

CompareTimes{T<:NetworkTimings}(n::Network,timings::Vector{T}, basetimes; args...) =
CompareTimes(n, AbstractArray{Float64,2}[t.times for t in timings], basetimes; args...)

CompareTimes{T<:NetworkStats}(n::Network, stats::Vector{T}, basetimes; args...) =
CompareTimes(n, AbstractArray{Float64,2}[s.times for s in stats], basetimes; args...)

function visualInit(v::ShowTimes)
    # Change the road colors to the first timing set
    updateRoadsColor(v)
    # change node color to black
    for n in v.nodes
        set_fillcolor(n, SFML.Color(0,0,0))
    end
end

function visualEvent(v::ShowTimes, event::Event)
    if get_type(event) == EventType.KEY_PRESSED
        if get_key(event).key_code == KeyCode.SPACE
            #move forward
            if v.currentTime < length(v.times)
                v.currentTime += 1
                updateRoadsColor(v)
            end
        elseif get_key(event).key_code == KeyCode.B
            #move backward
            if v.currentTime > 1
                v.currentTime -= 1
                updateRoadsColor(v)
            end
        end
    end
end


"""
    `updateRoadsColor`: update road color given timings
"""
function updateRoadsColor(v::ShowTimes)
    #change colors
    for ((o,d),r) in v.network.roads
        s = r.distance/v.times[v.currentTime][o,d]
        c = round(Int,max(0, min(1, (v.maxSpeed-s)/(v.maxSpeed-v.minSpeed))) * (length(v.palette)-1)) +1
        # c = round(Int,(s-v.minSpeed)/(v.maxSpeed-v.minSpeed) * (length(v.palette)-1)) +1
        color = v.palette[c]
        set_fillcolor(v.roads[o,d],Color(round(Int,color.r*255),round(Int,255*color.g),round(Int,255*color.b)))
    end
end
