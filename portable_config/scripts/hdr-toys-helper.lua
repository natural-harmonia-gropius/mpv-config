function math.clamp(x, min, max)
    if x < min then return min end
    if x > max then return max end
    return x
end

function set_hdr_white(w)
    w = math.clamp(w, 0, 10000)
    mp.command("no-osd set glsl-shader-opts WHITE_hdr=" .. w)
end

function set_sdr_white(w)
    w = math.clamp(w, 0, 1000)
    mp.command("no-osd set glsl-shader-opts WHITE_sdr=" .. w)
end

function set_exposure_bias(bias)
    bias = math.clamp(bias, 0, 100)
    mp.command("no-osd set glsl-shader-opts exposure/bias=" .. bias)
end

mp.observe_property("video-out-params", "native", function(_, value)
    if not value then
        return
    end

    local peak = value["sig-peak"];
    if not peak or peak == 1 then
        set_hdr_white(1000)
        set_exposure_bias(1)
        return
    end

    local exposure_bias = 1000 / 203 / peak
    set_hdr_white(203 * peak * exposure_bias)

    -- no darken
    if peak > 4.926 then
        set_exposure_bias(1)
        return
    end

    set_exposure_bias(exposure_bias)
end)
