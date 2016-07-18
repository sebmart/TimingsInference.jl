###################################################
## showtimes.jl
## Visualize one or several timings
###################################################

"""
    `ShowTimes`: Network visualizer that shows road times
    - `SPACE` to go forward, `B` to go back
"""
type ShowTimes <: NetworkVisualizer
    # Mandatory attributes
    network::Network
    window::RenderWindow
    nodes::Vector{CircleShape}
    roads::Dict{Tuple{Int,Int},Line}
    nodeRadius::Float64
    nodesToView::Vector{Node}


    "times to show"
    times::Vector{AbstractArray{Float64,2}}
    "current times values"
    currentTime::Int
    "color palette"
    palette::Vector{Colors.RGB{Float64}}
    "minimum speed"
    minSpeed::Float64
    "maximum speed"
    maxSpeed::Float64

    "contructor"
    function ShowTimes(n::Network, times::Vector{AbstractArray{Float64,2}}; speedRange::Tuple{Int,Int} = (-1,-1))
        if length(times) == 0
            error("Need at least one set of road times")
        end
                obj = new()
        obj.network  = n
        obj.nodesToView = n.nodes
        obj.times = times
        obj.currentTime = 1
        obj.palette = Colors.colormap("Blues")

        # if no speed range: compute it
        if speedRange == (-1,-1)
            minSpeed, maxSpeed = Inf, -Inf
            for ((o,d),r) in n.roads, t in 1:length(times)
                s = r.distance/times[t][o,d]
                s < minSpeed && (minSpeed = s)
                s > maxSpeed && (maxSpeed = s)
            end
            obj.minSpeed = minSpeed
            obj.maxSpeed = maxSpeed
            if minSpeed == maxSpeed
                obj.minSpeed *= 0.99
            end
        else
            (obj.minSpeed,obj.maxSpeed) = speedRange
        end
        return obj
    end
end

ShowTimes(n::Network,time::AbstractArray{Float64,2}; args...) = ShowTimes(n,AbstractArray{Float64,2}[time],args...)
ShowTimes(n::Network,timing::NetworkTimings; args...) = ShowTimes(n,AbstractArray{Float64,2}[timing.times],args...)
ShowTimes(n::Network,timings::Vector{NetworkTimings}; args...) = ShowTimes(n,AbstractArray{Float64,2}[t.times for t in timings],args...)
ShowTimes{T<:NetworkStats}(n::Network,stats::Vector{T}; args...) = ShowTimes(n, AbstractArray{Float64,2}[s.times for s in stats],args...)

function visualInit(v::ShowTimes)
    #Change the road colors to the first timing set
    updateRoadsColor(v)
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
        c = round(Int,(s-v.minSpeed)/(v.maxSpeed-v.minSpeed) * (length(v.palette)-1)) +1
        color = v.palette[c]
        set_fillcolor(v.roads[o,d],Color(round(Int,color.r*255),round(Int,255*color.g),round(Int,255*color.b)))
    end
end
