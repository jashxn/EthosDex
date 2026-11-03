--!strict
--!nolint LocalShadow

local Types = require(script.types)
local Constants = require(script.constants)
local CreateTheme = require(script.createTheme)
local ManageTheme = require(script.manageTheme)
local ThemeHelpers = require(script.themeHelpers)
local DefaultThemeConfig = require(script.defaultThemeConfig)

export type Theme = Types.Theme
export type ThemeSource = Types.ThemeSource
export type ThemeConfig = Types.ThemeConfig

export type BgVariant = Types.BgVariant
export type FgVariant = Types.FgVariant
export type AccentVariant = Types.AccentVariant
export type HeightVariant = Types.HeightVariant
export type CornerRadiusVariant = Types.CornerRadiusVariant
export type FontVariant = Types.FontVariant
export type FontSizeVariant = Types.FontSizeVariant
export type ThemeColorModifier = Types.ThemeColorModifier

return {
	CreateTheme = CreateTheme,
	SetThemeForScope = ManageTheme.SetThemeForScope,
	GetThemeForScope = ManageTheme.GetThemeForScope,
	CalcColorModifier = ThemeHelpers.CalcColorModifier,
	ApplyColorModifier = ThemeHelpers.ApplyColorModifier,
	GetNextVariant = ThemeHelpers.GetNextVariant,
	DefaultThemeConfig = DefaultThemeConfig.DefaultThemeConfig,
	WithConfigDefaults = DefaultThemeConfig.WithConfigDefaults,
	Types = Types,
	Constants = Constants,
}
