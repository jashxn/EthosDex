--!strict
--!nolint LocalShadow

local Fusion = require(script.Parent.Parent.Parent.packages.fusion)

local Oktween = require(script.Parent.Parent.fusionUtils.oktween)

local Types = require(script.Parent.types)
local ThemeHelpers = require(script.Parent.themeHelpers)
local CreateTheme = require(script.Parent.createTheme)

local Value = Fusion.Value

local THEME_COLOR_TWEEN_INFO = TweenInfo.new(
	.55,
	Enum.EasingStyle.Exponential,
	Enum.EasingDirection.InOut
)

type ManagedTheme = {
	Public: Types.Theme,
	Targets: { [string]: Fusion.Value<any> },
}

-- Per-scope managed theme registry. Scopes are plain tables (see the
-- vendored Fusion's deriveScope), so weak keys let themes die with their
-- scope.
local managedThemes = setmetatable({}, { __mode = "k" }) :: { [Fusion.Scope]: ManagedTheme }

local function CreateManagedTheme(scope: Fusion.Scope<unknown>, config: Types.ThemeConfig): ManagedTheme
	local source = CreateTheme(config)
	local targets: { [string]: Fusion.Value<any> } = {}

	local theme = {
		GetToken = ThemeHelpers.GetToken,
		GetBg = ThemeHelpers.GetBg,
		GetBgHighlight = ThemeHelpers.GetBgHighlight,
		GetFg = ThemeHelpers.GetFg,
		GetAccent = ThemeHelpers.GetAccent,
		GetAccentFg = ThemeHelpers.GetAccentFg,
		GetHeight = ThemeHelpers.GetHeight,
		GetCornerRadius = ThemeHelpers.GetCornerRadius,
		GetFont = ThemeHelpers.GetFont,
		GetFontSize = ThemeHelpers.GetFontSize,
		HighlightGradient = ThemeHelpers.HighlightGradient,
		ApplyColorModifier = ThemeHelpers.ApplyColorModifier,
		GetNextVariant = ThemeHelpers.GetNextVariant,
	} :: any

	for key, sourceValue in pairs(source) do
		local target = Value(scope, sourceValue)

		targets[key] = target
		theme[key] = if typeof(sourceValue) == "Color3" then Oktween(
				scope,
				target,
				THEME_COLOR_TWEEN_INFO
			)
			else target
	end

	return {
		Public = theme,
		Targets = targets,
	}
end

local function UpdateTheme(managedTheme: ManagedTheme, config: Types.ThemeConfig)
	local source = CreateTheme(config)

	for key, target in pairs(managedTheme.Targets) do
		target:set(source[key])
	end
end

-- Register (or refresh) the theme for a scope. New scopes get a fresh
-- managed theme; existing scopes re-generate their tokens in place.
local function SetThemeForScope(scope: Fusion.Scope<unknown>, config: Types.ThemeConfig)
	local managedTheme = managedThemes[scope]

	if managedTheme then
		UpdateTheme(managedTheme, config)
	else
		managedThemes[scope] = CreateManagedTheme(scope, config)
	end
end

-- Returns nil when the scope has no registered theme (callers fall back
-- to their library-level theme).
local function GetThemeForScope(scope: Fusion.Scope<unknown>): Types.Theme?
	local managedTheme = managedThemes[scope]

	return managedTheme and managedTheme.Public or nil
end

return {
	SetThemeForScope = SetThemeForScope,
	GetThemeForScope = GetThemeForScope,
}
