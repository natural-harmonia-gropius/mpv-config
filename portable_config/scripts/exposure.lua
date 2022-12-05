mp.observe_property("video-out-params", "native", function(_, params)
    if not params then return end

    local peak = params["sig-peak"];
    if not peak or peak == 1 or peak > 4.926 then return end

    local exposure_bias = 1000 / 203 / peak
    mp.command("no-osd set glsl-shader-opts exposure/bias=" .. exposure_bias)
end)
