function math.clamp(x, min, max)
    if x < min then return min end
    if x > max then return max end
    return x
end

function math.round(x)
    return math.floor(x + 0.5)
end

function set_hdr_white(w)
    w = math.clamp(w, 0, 10000)
    mp.command("no-osd set glsl-shader-opts L_hdr=" .. w)
end

mp.observe_property("video-out-params", "native", function(_, value)
    if not value then
        return
    end

    local peak = value["sig-peak"];
    if not peak or peak == 1 then
        return
    end

    mp.add_timeout(0.1, function ()
        set_hdr_white(math.round(203 * peak))
    end)
end)
