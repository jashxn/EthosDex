--!strict
-- Generative theme constants: contrast anchors and reference colors for the
-- extended palette.

local BASE_LIGHT_TEXT_COLOR = Color3.fromHex("#F8FAFC")
local BASE_DARK_TEXT_COLOR = Color3.fromHex("#09090B")

-- Extended palette seeds. Each named theme only provides its background
-- base color and accent seeds; these hues are shared across every theme
-- and are re-generated with a lightness floor so they stay visible on
-- the theme's background tiers.
local COLOR_SEEDS = {
	Blue = Color3.fromRGB(40, 80, 180),
	Brown = Color3.fromRGB(120, 80, 50),
	Cyan = Color3.fromRGB(40, 170, 190),
	Gray = Color3.fromRGB(80, 80, 80),
	Green = Color3.fromRGB(40, 150, 80),
	Magenta = Color3.fromRGB(180, 60, 180),
	Orange = Color3.fromRGB(230, 120, 40),
	Pink = Color3.fromRGB(230, 100, 150),
	Purple = Color3.fromRGB(110, 60, 170),
	Red = Color3.fromRGB(200, 50, 50),
	Success = Color3.fromRGB(50, 200, 70),
	Violet = Color3.fromRGB(140, 80, 200),
	White = Color3.fromRGB(200, 200, 200),
	Yellow = Color3.fromRGB(230, 200, 60),
}

return {
	BASE_LIGHT_TEXT_COLOR = BASE_LIGHT_TEXT_COLOR,
	BASE_DARK_TEXT_COLOR = BASE_DARK_TEXT_COLOR,
	COLOR_SEEDS = COLOR_SEEDS,
}
