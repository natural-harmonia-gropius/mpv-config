-- celebi.lua
--
-- This Pokémon wanders across time. It restores properties from past sessions.

local msg = require "mp.msg"

local function read_options(options, identifier, path, on_update)
    if identifier == nil then
        identifier = mp.get_script_name()
    end
    if not path then
        msg.debug("reading options for " .. identifier)
    end

    -- read config file
    local conffilename, conffile
    if path then
        conffile = path
    else
        conffilename = "script-opts/" .. identifier .. ".conf"
        conffile = mp.find_config_file(conffilename)
        if conffile == nil then
            msg.debug(conffilename .. " not found.")
            conffilename = "lua-settings/" .. identifier .. ".conf"
            conffile = mp.find_config_file(conffilename)
            if conffile then
                msg.warn("lua-settings/ is deprecated, use directory script-opts/")
            end
        end
    end
    local f = conffile and io.open(conffile, "r")
    if f == nil then
        -- config not found
        if not path then
            msg.debug(conffilename .. " not found.")
        end
    else
        -- config exists, read values
        if not path then
            msg.verbose("Opened config file " .. conffilename .. ".")
        end
        for line in f:lines() do
            if line:sub(#line) == "\r" then
                line = line:sub(1, #line - 1)
            end
            if string.find(line, "#") == 1 then

            else
                local eqpos = string.find(line, "=")
                if eqpos == nil then

                else
                    local key = string.sub(line, comment and 2 or 1, eqpos-1)
                    local val = string.sub(line, eqpos+1)

                    if path then
                        options[key] = val
                    else
                        options[key] = val == "yes"
                    end
                end
            end
        end
        io.close(f)
    end

    if path then
        return
    end

    --parse command-line options
    local prefix = identifier.."-"
    -- command line options are always applied on top of these

    local function parse_opts(full, options)
        local changelist = {}
        for key, val in pairs(full) do
            if string.find(key, prefix, 1, true) == 1 then
                key = string.sub(key, string.len(prefix)+1)
                value = val == "yes"

                if options[key] ~= value then
                    changelist[key] = options[key] == nil
                end

                options[key] = value
            end
        end
        return changelist
    end

    --initial
    parse_opts(mp.get_property_native("options/script-opts"), options)

    --runtime updates
    if on_update then
        mp.observe_property("options/script-opts", "native", function(name, val)
            local changelist = parse_opts(val, options)
            if next(changelist) ~= nil then
                on_update(changelist)
            end
        end)
    end

end

--- #0251

local init = false
local shutdown = false
local state = {}
local last_state = {}
local state_path
local save_cooldown
local options = {}

local function update_property(property, val)
    state[property] = val
end

local function observe_new(changelist)
    for property, new in pairs(changelist) do
        if new then
            mp.observe_property(property, "native", update_property)
        end
    end
end

local function save_state()
    local f = io.open(state_path, "w")
    for property, val in pairs(last_state) do
        if val ~= nil then
            f:write(property, "=", tostring(val), "\n")
        end
    end
    f:close()
end

local function watch_changes()
    if save_cooldown then return end

    if not init then
        state_path, found = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("([\\/])scripts[\\/][^\\/]+%.lua$", "%1")
        if found > 0 then
            state_path = state_path .. "celebi.txt"
        else
            state_path = mp.command_native({"expand-path", "~~/celebi.txt"})
        end
        read_options(state, "celebi", state_path)
        for property, enabled in pairs(options) do
            if enabled and state[property] ~= nil and not mp.get_property_bool("option-info/"..property.."/set-from-commandline", false) then
                mp.set_property(property, state[property])
            end
        end
    end

    local dirty = false
    for property, val in pairs(state) do
        if not init then
            last_state[property] = state[property]
        end
        if options[property] then
            if last_state[property] ~= state[property] then
                dirty = true
            end
            last_state[property] = val
        end
    end

    init = true

    if dirty then
        save_state()
        if shutdown then return end
        save_cooldown = mp.add_timeout(1, function()
            save_cooldown = nil
        end)
    end
end

read_options(options, "celebi", nil, observe_new)

for property, enabled in pairs(options) do
    mp.observe_property(property, "string", update_property)
end

mp.register_idle(watch_changes)

mp.register_event("shutdown", function()
    save_cooldown = nil
    shutdown = true
    watch_changes()
end)
