local utils = require("mp.utils")

local bind_map = {}

local event_pattern = {
    { from = "press", to = "click" },
    { from = "down,up,down,up", to = "double_click" },
    { from = "down,up", to = "click" },
    { from = "down", to = "press" },
    { from = "up", to = "release" },
}

local event_immediate = { "repeat" }

-- https://mpv.io/manual/master/#input-command-prefixes
local prefixes = { "osd-auto", "no-osd", "osd-bar", "osd-msg", "osd-msg-bar", "raw", "expand-properties", "repeatable",
    "async", "sync" }

-- https://mpv.io/manual/master/#list-of-input-commands
local commands = { "set", "cycle", "add", "multiply" }

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

function get_invert(action)
    local invert = ""
    local action = action:split(";")
    for i, v in ipairs(action) do
        local subs = v:trim():split("%s*")
        local prefix = table.has(prefixes, subs[1]) and subs[1] or ""
        local command = subs[prefix == "" and 1 or 2]
        local property = subs[prefix == "" and 2 or 3]
        local value = mp.get_property(property)
        local semi = i == #action and "" or ";"

        if table.has(commands, command) then
            invert = invert .. prefix .. " set " .. property .. " " .. value .. semi
        else
            mp.msg.error("\"" .. v:trim() .. "\" doesn't support auto restore.")
        end
    end
    return invert
end

function table:has(element)
    for _, value in ipairs(self) do
        if value == element then
            return true
        end
    end
    return false
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

function string:trim()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
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

local InputEvent = {}

function InputEvent:new(key, on)
    local Instance = {}
    setmetatable(Instance, self);
    self.__index = self;

    Instance.key = key
    Instance.name = "@" .. key
    Instance.on = on or {}
    Instance.queue = {}
    Instance.duration = mp.get_property_number("input-doubleclick-time", 300)

    return Instance
end

function InputEvent:handler(e)
    local event = e.event

    if table.has(event_immediate, event) then
        self:emit(event)
        return
    end

    self.queue = table.push(self.queue, event)
    self.exec()
end

function InputEvent:emit(event)
    local cmd = self.on[event]
    if cmd and cmd ~= "" then
        command(cmd)
    end
end

function InputEvent:bind()
    self.exec = debounce(function()
        local separator = ","

        local queue_string = table.join(self.queue, separator)
        for _, v in ipairs(event_pattern) do
            queue_string = queue_string:replace(v.from, v.to)
        end

        local commands = queue_string:split(separator)
        for index, event in ipairs(commands) do
            local auto_restore = self.on["release"] == "ignore"

            if event == "press" and auto_restore then
                self.on["release-auto"] = get_invert(self.on["press"])
            end

            if event == "release" and auto_restore then
                event = "release-auto"
            end

            self:emit(event)
        end

        self.queue = {}
    end, self.duration)

    mp.add_forced_key_binding(self.key, self.name, function(e) self:handler(e) end, { complex = true })
end

function InputEvent:unbind()
    mp.remove_key_binding(self.name)
end

function bind(key, on)
    if bind_map[key] then
        bind_map[key]:unbind()
    end

    if type(on) == "string" then
        on = utils.parse_json(on)
    end

    bind_map[key] = InputEvent:new(key, on)
    bind_map[key]:bind()
end

function bind_from_input_conf()
    local input_conf = mp.get_property_native("input-conf")
    local input_conf_path = mp.command_native({ "expand-path", input_conf == "" and "~~/input.conf" or input_conf })
    local input_conf_meta, meta_error = utils.file_info(input_conf_path)
    if not input_conf_meta or not input_conf_meta.is_file then return end -- File doesn"t exist

    local parsed = {}
    for line in io.lines(input_conf_path) do
        line = line:trim()
        if line ~= "" then
            local key, cmd, event = line:match("%s*([%S]+)%s+(.-)%s+#@%s*(.-)%s*$")
            if event and event ~= "" then
                if parsed[key] == nil then
                    parsed[key] = {}
                end

                parsed[key][event] = cmd
            end
        end
    end
    for key, on in pairs(parsed) do
        bind(key, on)
    end
end

function unbind(key)
    bind_map[key]:unbind()
end

bind_from_input_conf()

mp.observe_property("input-doubleclick-time", "native", function(_, new_duration)
    for key, on in pairs(bind_map) do
        on.duration = new_duration
        on:unbind()
        on:bind()
    end
end)

mp.register_script_message("bind", bind)
mp.register_script_message("unbind", unbind)