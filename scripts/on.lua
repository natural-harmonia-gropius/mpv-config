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

function table:join(separator)
    local result = ""
    for i, v in ipairs(self) do
        local value = type(v) == "string" and v or tostring(v)
        local semi = i == #self and "" or separator
        result = result .. value .. semi
    end
    return result
end

function string:replace(pattern, replacement)
    local result, n = self:gsub(pattern, replacement)
    return result
end

function string:split(separator)
    local fields = {}
    local separator = separator or ":"
    local pattern = string.format("([^%s]+)", separator)
    local copy = self:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

local On = {}

function On:new(key, on, duration)
    local Instance = {}
    setmetatable(Instance, self);
    self.__index = self;

    Instance.key = key
    Instance.name = "@" .. key
    Instance.on = on or {}
    Instance.duration = duration or 200
    Instance.queue = {}

    return Instance
end

function On:handler(e)
    self.queue = table.push(self.queue, e.event)
    self.exec()
end

function On:bind()
    self.exec = debounce(function()
        local separator = ","
        local queue_string = table.join(self.queue, separator)
        queue_string = queue_string:replace("down,up,down,up", "double_click")
        queue_string = queue_string:replace("down,up", "click")
        queue_string = queue_string:replace("down", "press")
        queue_string = queue_string:replace("up", "release")
        local commands = queue_string:split(separator)

        for index, value in ipairs(commands) do
            command(self.on[value])
        end

        self.queue = {}
    end, self.duration)

    mp.add_forced_key_binding(self.key, self.name, function(e) self:handler(e) end, { complex = true })
end

function On:unbind()
    mp.remove_key_binding(self.name)
end

local on = On:new("MBTN_LEFT", {
    click = "cycle pause",
    double_click = "cycle fullscreen",
    press = "show-text pressed",
    release = "show-text released",
})
on:bind()
