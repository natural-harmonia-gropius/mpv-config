local opt = require("mp.options")
local options = {
    bind = "MBTN_LEFT",
    action = "cycle pause",
    duration = 200
}
opt.read_options(options)

local keydown_at = 0
-- local original = ""

-- it doesn't work
-- function get_key_binding(key)
--     for _, v in ipairs(mp.get_property_native("input-bindings")) do
--         print(v.key, " ", v.cmd)
--         if v.key == key then
--             return v.cmd
--         end
--     end
--     return "ignore"
-- end

function now()
    return mp.get_time() * 1000
end

function command(command)
    return mp.command(command)
end

function keydown(key_name, key_text, is_mouse)
    keydown_at = now()
    -- original = get_key_binding(options.bind)
end

function keyup(key_name, key_text, is_mouse)
    if now() - keydown_at < options.duration then
        command(options.action)
    end
end

function keypress(key_name, key_text, is_mouse)
end

function keyrepeat(key_name, key_text, is_mouse)
end

function event_handler(event, is_mouse, key_name, key_text)
    if event == "down" then
        keydown(key_name, key_text, is_mouse)
    elseif event == "up" then
        keyup(key_name, key_text, is_mouse)
    elseif event == "press" then
        keypress(key_name, key_text, is_mouse)
    elseif event == "repeat" then
        keyrepeat(key_name, key_text, is_mouse)
    else
        print(event, key_name, key_text, is_mouse)
    end
end

mp.add_forced_key_binding(options.bind, nil, function(e)
    event_handler(e.event, e.is_mouse, e.key_name, e.key_text)
end, {
    complex = true
})
