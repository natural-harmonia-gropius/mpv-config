local function debounce(func, wait)
    func = type(func) == "function" and func or function() end
    wait = type(wait) == "number" and wait / 1000 or 0

    local timer = nil
    local timer_end = function()
        timer:kill()
        timer = nil
        func()
    end

    return function()
        if timer then
            timer:kill()
        end
        timer = mp.add_timeout(wait, timer_end)
    end
end

function now()
    return mp.get_time() * 1000
end

function command(command)
    return mp.command(command)
end

function table:push(element)
    self[#self + 1] = element
    return self
end

function table:assign(source)
    for key, value in pairs(source) do
        self[key] = value
    end
    return self
end

local target = {
    name = "",
    key = "MBTN_LEFT",
    click = "cycle pause",
    double_click = "cycle fullscreen",
    press = "show-text pressed",
    release = "show-text released",
    duration = 200,
    queue = {},
}

function target:handler(e)
    local queue_item = {
        event = e.event,
        at = now()
    }
    self.queue = table.push(self.queue, queue_item)
    self.exec()
end

function target:bind()
    self.name = self.name or ("@" .. self.key)
    self.exec = debounce(function()
        function dump(o)
            if type(o) == 'table' then
                local s = '{ '
                for k, v in pairs(o) do
                    if type(k) ~= 'number' then k = '"' .. k .. '"' end
                    s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
                end
                return s .. '} '
            end
            return tostring(o)
        end

        local queue = self.queue
        local length = #queue
        local last = queue[length]
        local lantency = now() - last.at
        local str = dump(queue)

        print("lantency:", lantency, "length:", length, "toString:", str)

        if length == 1 then
            if last.event == "down" then
                command(self.press)
            elseif last.event == "up" then
                command(self.release)
            end
        elseif length == 2 then
            -- down, up
            command(self.click)
        elseif length == 3 then
            if last.event == "down" then
                -- down, up, down
                command(self.click)
                command(self.press)
            elseif last.event == "up" then
                -- up, down, up
                command(self.release)
                command(self.click)
            end
        elseif length == 4 then
            -- down, up, down, up
            command(self.double_click)
        end

        self.queue = {}
    end, self.duration)

    mp.add_forced_key_binding(self.key, self.name, function(e) self:handler(e) end, { complex = true })
end

function target:unbind()
    mp.remove_key_binding(self.name)
end

target:bind()
