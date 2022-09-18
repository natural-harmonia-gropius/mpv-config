function command(command)
    mp.command(command .. '; show-text ""')
end

function event_handler(event, is_mouse, key_name, key_text)
    if      event == 'down'     then command('set speed 3')
    elseif  event == 'up'       then command('set speed 1')
    elseif  event == 'press'    then
    elseif  event == 'repeat'   then
    else
    end
end

mp.add_forced_key_binding("RIGHT", nil, function (e) event_handler(e.event, e.is_mouse, e.key_name, e.key_text) end, { complex = true })