local themeLoaders = {
	eclipse = script.eclipse,
	ember = script.ember,
	gold = script.gold,
	graphite = script.graphite,
	jade = script.jade,
	midnight = script.midnight,
	orchid = script.orchid,
	rose = script.rose,
	obsidian = script.obsidian,
	abyss = script.abyss,
	frost = script.frost,
	crimson = script.crimson,
	lagoon = script.lagoon,
	lavender = script.lavender,
	sunset = script.sunset,
	citrus = script.citrus,
	cobalt = script.cobalt,
	sakura = script.sakura,
	moss = script.moss,
	["high contrast"] = script.highContrast,
	terminal = script.terminal,
	synthwave = script.synthwave,
	coffee = script.coffee,
	paper = script.paper,
	daylight = script.daylight,
	sandstone = script.sandstone,
	["catppuccin mocha"] = script.catppuccinMocha,
	["catppuccin macchiato"] = script.catppuccinMacchiato,
	["catppuccin frappé"] = script.catppuccinFrappe,
	["catppuccin latte"] = script.catppuccinLatte,
	dracula = script.dracula,
	nord = script.nord,
	["gruvbox dark"] = script.gruvboxDark,
	["gruvbox light"] = script.gruvboxLight,
	["tokyo night"] = script.tokyoNight,
	["one dark"] = script.oneDark,
	["solarized dark"] = script.solarizedDark,
	["solarized light"] = script.solarizedLight,
	["rosé pine"] = script.rosePine,
	["rosé pine moon"] = script.rosePineMoon,
	["rosé pine dawn"] = script.rosePineDawn,
	kanagawa = script.kanagawa,
	everforest = script.everforest,
	["ayu dark"] = script.ayuDark,
	["ayu mirage"] = script.ayuMirage,
	["github dark"] = script.githubDark,
	["github light"] = script.githubLight,
	monokai = script.monokai,
	palenight = script.palenight,
	["night owl"] = script.nightOwl,
	["synthwave '84"] = script.synthwave84,
	vesper = script.vesper,
	poimandres = script.poimandres,
	oxocarbon = script.oxocarbon,
	horizon = script.horizon,
}

local loadedThemes = {}
local customThemes = {}

local function deepFreeze(tbl)
	if type(tbl) ~= "table" or table.isfrozen(tbl) then
		return tbl
	end
	for _, value in pairs(tbl) do
		if type(value) == "table" and not table.isfrozen(value) then
			deepFreeze(value)
		end
	end
	return table.freeze(tbl)
end

local function getTheme(name)
	if customThemes[name] then
		return customThemes[name]
	end
	if loadedThemes[name] then
		return loadedThemes[name]
	end
	local loader = themeLoaders[name]
	if not loader then
		return nil
	end
	local theme = require(loader)
	deepFreeze(theme)
	loadedThemes[name] = theme
	return theme
end

local function getThemeNames()
	local names = {}
	for name in pairs(themeLoaders) do
		table.insert(names, name)
	end
	for name in pairs(customThemes) do
		table.insert(names, name)
	end
	table.sort(names)
	return table.freeze(names)
end

local function isPreset(name)
	return themeLoaders[name] ~= nil
end

local function define(key, config)
	assert(not isPreset(key), `"{key}" is a built-in theme`)
	customThemes[key] = deepFreeze(table.clone(config))
end

local function remove(key)
	customThemes[key] = nil
end

return table.freeze({
	getTheme = getTheme,
	getThemeNames = getThemeNames,
	isPreset = isPreset,
	define = define,
	remove = remove,
})
