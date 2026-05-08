local count = 0
function observer(_, dimensions)
    count = count + 1
    -- The first, value will be 0x0
    -- The second, value will be the default dimensions
    -- The third, value will be the dimensions after resizing
    if count == 3 then
        mp.commandv('set', 'auto-window-resize', 'no')
    end
end
mp.observe_property('osd-dimensions', 'native', observer)
