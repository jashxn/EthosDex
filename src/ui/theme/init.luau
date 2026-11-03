--!nolint LocalShadow
local Root = script.Parent.Parent
local Fusion = require(Root.packages.fusion)
local States = require(Root.packages.states)
local Internal = require(Root.packages.internal)
local Themes = require(Root.ui.theme.palettes)
local ThemeUtils = require(Root.utils.themeUtils)

local scope = Internal.Scope

local peek = Fusion.peek

local currentThemeName = States.Theme

local function GetThemeConfig(themeName: string)
	return ThemeUtils.WithConfigDefaults(Themes.getTheme(themeName))
end

local function BuildTheme()
	LPH_ATTRIBUTES(VM(NONE), PRESET(FAST), ERROR_HANDLING(false))
	ThemeUtils.SetThemeForScope(scope, GetThemeConfig(peek(currentThemeName)))
end

BuildTheme()

Fusion.Observer(scope, currentThemeName):onChange(BuildTheme)

local theme = ThemeUtils.GetThemeForScope(scope) :: any

local function GetSupportedThemes()
	return Themes.getThemeNames()
end

local function SetTheme(themeName)
	if Themes.getTheme(themeName) then
		currentThemeName:set(themeName)
	end
end

local function Preview(config)
	if config then
		ThemeUtils.SetThemeForScope(scope, ThemeUtils.WithConfigDefaults(config))
	else
		BuildTheme()
	end
end

local function Define(key: string, config)
	Themes.define(key, config)
	if peek(currentThemeName) == key then
		BuildTheme()
	end
end

local function Remove(key: string)
	Themes.remove(key)
end

local function Generate(config)
	return ThemeUtils.CreateTheme(ThemeUtils.WithConfigDefaults(config))
end

theme.GetThemeForScope = function(themeScope)
	return ThemeUtils.GetThemeForScope(themeScope) or theme
end
theme.SetThemeForScope = ThemeUtils.SetThemeForScope
theme.GetNextVariant = ThemeUtils.GetNextVariant
theme.CalcColorModifier = ThemeUtils.CalcColorModifier
theme.ApplyColorModifier = function(themeScope, color, modifier)
	return ThemeUtils.ApplyColorModifier(theme, themeScope, color, modifier)
end

theme.GetSupportedThemes = GetSupportedThemes
theme.SetTheme = SetTheme
theme.GetThemeConfig = GetThemeConfig
theme.IsPreset = Themes.isPreset
theme.Preview = Preview
theme.Define = Define
theme.Remove = Remove
theme.Generate = Generate

return theme
