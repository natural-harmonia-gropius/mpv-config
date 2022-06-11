local intl_dir = mp.get_script_directory() .. '/intl/'
local locale = {}

-- https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/supported-languages?pivots=store-installer-msix#list-of-supported-languages
function get_languages()
	local languages = {}

	for _, lang in ipairs(split(options.languages, ',')) do
		if (lang == 'slang') then
			local slang = mp.get_property_native('slang')
			if slang then
				itable_append(languages, slang)
			end
		else
			itable_append(languages, { lang })
		end
	end

	return languages
end

---@param path string
function get_locale_from_json(path)
	local expand_path = mp.command_native({ 'expand-path', path })

	local meta, meta_error = utils.file_info(expand_path)
	if not meta or not meta.is_file then
		return {}
	end

	local json_file = io.open(expand_path, 'r')
	if not json_file then
		return {}
	end

	local json = json_file:read('*all')
	json_file:close()

	return utils.parse_json(json)
end

---@param path string
function make_locale(path)
	local translations = {}
	local languages = get_languages()
	for i = #languages, 1, -1 do
		lang = languages[i]
		if (lang:match('.json$')) then
			table_assign(translations, get_locale_from_json(lang))
		elseif (lang == 'en') then
			translations = {}
		else
			table_assign(translations, get_locale_from_json(path .. lang:lower() .. '.json'))
		end
	end

	return translations
end

function init()
	locale = make_locale(intl_dir)
end

---@param text string
function t(text, ...)
	if not text then
		return ''
	end

	local trans = locale[text] or text

	local arg = { ... }
	if #arg > 0 then
		local key = text
		for _, value in ipairs(arg) do
			key = key .. '|' .. value
		end
		if not locale[key] then
			locale[key] = string.format(trans, unpack(arg))
		end
		return locale[key]
	end

	return trans
end

init()

return { t = t }
