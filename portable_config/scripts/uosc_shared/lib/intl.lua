local translations = {}

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

---@param lang string
function get_translations_from_intl(lang)
	local status, trans = pcall(require, 'uosc_shared/intl/' .. lang:lower())
	if (status) then
		return trans
	end

	return {}
end

---@param path string
function get_translations_from_json(path)
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

function get_translations()
	local translations = {}
	for _, lang in ipairs(get_languages()) do

		if (lang:match('.json$')) then
			table_assign(translations, get_translations_from_json(lang))
		else
			table_assign(translations, get_translations_from_intl(lang))
		end
	end

	return translations
end

---@param text string
function t(text)
	local t = translations[text]
	return t or text
end

translations = get_translations()

return t
