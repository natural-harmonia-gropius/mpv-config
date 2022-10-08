local msg = require("mp.msg")
local opt = require("mp.options")
local utils = require("mp.utils")

local options = {
    duration = 200
}
opt.read_options(options)

local bind_map = {}

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
            msg.error("\"" .. v:trim() .. "\" doesn't support auto restore.")
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

local On = {}

function On:new(key, on)
    local Instance = {}
    setmetatable(Instance, self);
    self.__index = self;

    Instance.key = key
    Instance.name = "@" .. key
    Instance.on = on or {}
    Instance.duration = options.duration
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
            local auto_restore = self.on["release"] == "ignore"

            if value == "press" and auto_restore then
                self.on["release-auto"] = get_invert(self.on["press"])
            end

            if value == "release" and auto_restore then
                value = "release-auto"
            end

            local cmd = self.on[value]
            if cmd and cmd ~= "" then
                command(cmd)
            end
        end

        self.queue = {}
    end, self.duration)

    mp.add_forced_key_binding(self.key, self.name, function(e) self:handler(e) end, { complex = true })
end

function On:unbind()
    mp.remove_key_binding(self.name)
end

function bind(key, on)
    -- TODO: Is "on" a "table"?
    bind_map[key] = On:new(key, on)
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
            local key, cmd, on = line:match("%s*([%S]+)%s+(.-)%s+#@%s*(.-)%s*$")
            if on and on ~= "" then
                if parsed[key] == nil then
                    parsed[key] = {}
                end

                parsed[key][on] = cmd
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

mp.register_script_message("bind", bind)
mp.register_script_message("unbind", unbind)
