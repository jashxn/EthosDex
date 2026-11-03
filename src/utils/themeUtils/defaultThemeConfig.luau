--!strict

local Types = require(script.Parent.types)

-- Default generative theme config. Named themes in src/ui/theme/palettes
-- only override the seed colors; everything else falls back to these
-- layout/font defaults.
local function DefaultThemeConfig(): Types.ThemeConfig
	return {
		BgBaseColor = Color3.fromRGB(18, 18, 22),
		AccentPrimary = Color3.fromRGB(70, 100, 210),
		AccentSecondary = Color3.fromRGB(55, 165, 185),
		AccentCaution = Color3.fromHex("#A47103"),
		AccentDestructive = Color3.fromHex("#BE123C"),
		HeightSm = 24,
		HeightMd = 28,
		HeightLg = 36,
		FontMain = Font.new("rbxassetid://12187365364"),
		FontMono = Font.fromName("RobotoMono"),
		FontMainTitleSize = 15,
		FontMainBodySize = 14,
		FontMainCaptionSize = 12,
		FontMonoTitleSize = 14,
		FontMonoBodySize = 13,
		FontMonoCaptionSize = 12,
	}
end

-- Fill every missing config key with its default. Configs coming from the
-- theme registry are frozen, so this returns a merged clone.
local function WithConfigDefaults(config: Types.ThemeConfig?): Types.ThemeConfig
	if not config then
		return DefaultThemeConfig()
	end

	local merged = table.clone(DefaultThemeConfig())
	for key, value in pairs(config) do
		merged[key] = value
	end
	return merged
end

return {
	DefaultThemeConfig = DefaultThemeConfig,
	WithConfigDefaults = WithConfigDefaults,
}
