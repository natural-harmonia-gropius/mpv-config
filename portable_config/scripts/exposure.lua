function set_exposure_bias(bias)
    mp.command("no-osd set glsl-shader-opts exposure/bias=" .. bias)
end

mp.observe_property("video-out-params", "native", function(_, params)
    if not params then
        return
    end

    local peak = params["sig-peak"];
    if not peak or peak == 1 then
        set_exposure_bias(1)
        return
    end

    if peak > 4.926 then
        set_exposure_bias(1)
        return
    end

    set_exposure_bias(1000 / 203 / peak)
end)
