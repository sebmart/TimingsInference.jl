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


    "times to show"
    times::Vector{AbstractArray{Float64,2}}
    "current times values"
    currentTime::Int
    "color palette"
    palette::Vector{Colors.RGB{Float64}}

    "contructor"
    function ShowTimes(n::Network, times::Vector{AbstractArray{Float64,2}})
        obj = new()
        obj.network  = n
        obj.times = times
        obj.currentTime = 1
        obj.palette = Colors.colormap("Blues")
        if length(times) == 0
            error("Need at least one set of road times")
        end
        return obj
    end
end

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
    #load min and max speed
    minSpeed, maxSpeed = Inf, -Inf
    for ((o,d),r) in v.network.roads
        s = r.distance/v.times[v.currentTime][o,d]
        s < minSpeed && (minSpeed = s)
        s > maxSpeed && (maxSpeed = s)
    end
    #change colors
    for ((o,d),r) in v.network.roads
        s = r.distance/v.times[v.currentTime][o,d]
        c = round(Int,(s-minSpeed)/(maxSpeed-minSpeed) * (length(v.palette)-1)) +1
        color = v.palette[c]
        set_fillcolor(v.roads[o,d],Color(round(Int,color.r*255),round(Int,255*color.g),round(Int,255*color.b)))
    end
end
