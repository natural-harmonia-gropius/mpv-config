local count = 0
function observer(_, dimensions)
    count = count + 1
    if count == 3 then
        mp.commandv('set', 'auto-window-resize', 'no')
    end
end
mp.observe_property('osd-dimensions', 'native', observer)
