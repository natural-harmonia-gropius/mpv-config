local opt = require('mp.options')
local options = {
    bind = 'SPACE',
    action = 'set speed 4; set pause no',
    duration = 200
}
opt.read_options(options)

local pressed = false
local keydown_at = 0
local original = 'ignore'
local invert = ''

function now()
    return mp.get_time() * 1000
end

function command(command)
    return mp.command(command .. '; show-text ""')
end

function get_key_binding(key)
    for _, v in ipairs(mp.get_property_native('input-bindings')) do
        if v.key == key then
            return v.cmd
        end
    end
end

function get_invert(action)
    local invert = ''

    -- todo: follow the action
    local p = {'speed', 'pause'}
    for i, command in pairs(p) do
        local value = mp.get_property(command)
        local semi = i == #p and '' or ';'
        invert = invert .. 'set ' .. command .. ' ' .. value .. semi
    end

    return invert
end

function keydown(key_name, key_text, is_mouse)
    keydown_at = now()
    original = get_key_binding(options.bind)
    invert = get_invert(options.action)
end

function keyup(key_name, key_text, is_mouse)
    command(pressed and invert or original)
    pressed = false
    keydown_at = 0
end

function keypress(key_name, key_text, is_mouse)
end

function keyrepeat(key_name, key_text, is_mouse)
    if pressed then
        return
    end

    if now() - keydown_at < options.duration then
        return
    end

    pressed = true
    command(options.action)
end

function event_handler(event, is_mouse, key_name, key_text)
    if event == 'down' then
        keydown(key_name, key_text, is_mouse)
    elseif event == 'up' then
        keyup(key_name, key_text, is_mouse)
    elseif event == 'press' then
        keypress(key_name, key_text, is_mouse)
    elseif event == 'repeat' then
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
