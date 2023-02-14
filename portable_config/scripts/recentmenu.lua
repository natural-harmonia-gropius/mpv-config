local utils = require("mp.utils")
local options = require("mp.options")

local o = {
    path = "~~/recent.json",
    length = 10,
}
options.read_options(o)

local path = mp.command_native({ "expand-path", o.path })

local menu = {
    type = 'recent_menu',
    title = 'Recently played',
    items = { { title = 'Nothing here', value = 'ignore' } },
}

function read_json()
    local meta, meta_error = utils.file_info(path)
    if not meta or not meta.is_file then return end

    local json_file = io.open(path, "r")
    if not json_file then return end

    local json = json_file:read("a")
    json_file:close()

    menu.items = utils.parse_json(json)
end

function write_json()
    local json_file = io.open(path, "w")
    if not json_file then return end

    local json = utils.format_json(menu.items)

    json_file:write(json)
    json_file:close()
end

function append_item(path, filename, title)
    local new_items = {}
    new_items[1] = { title = filename, hint = title, value = { "loadfile", path } }
    for index, value in ipairs(menu.items) do
        if #new_items < o.length and value.value ~= "ignore" and value.value[2] ~= path then
            new_items[#new_items + 1] = value
        end
    end
    menu.items = new_items
    write_json()
end

function open_menu()
    read_json()
    local json = utils.format_json(menu)
    mp.commandv('script-message-to', 'uosc', 'open-menu', json)
end

function get_filename_without_ext(filename)
    local idx = filename:match(".+()%.%w+$")
    if idx then
        filename = filename:sub(1, idx - 1)
    end
    return filename
end

function on_load()
    local path = mp.get_property("path")
    if not path then return end
    local filename = mp.get_property("filename")
    local filename_without_ext = get_filename_without_ext(filename)
    local title = mp.get_property("media-title") or path
    if filename == title or filename_without_ext == title then
        title = ""
    end
    append_item(path, filename, title)
end

mp.add_key_binding(nil, "open", open_menu)
mp.register_event("file-loaded", on_load)

read_json()
