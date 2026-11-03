local utils = require(script.Parent.utils)
local hex = utils.hex

-- Frost: Steel-blue surfaces with an icy accent.
return {
	name = "frost",
	title = "Frost",
	BgBaseColor = hex("#141a22"),
	AccentPrimary = hex("#7cc4f2"),
	AccentSecondary = hex("#9aa8f5"),
	AccentCaution = hex("#e9b354"),
	AccentDestructive = hex("#f06b74"),
	Overrides = {
		FgPrimary = hex("#f0f4f9"),
		FgSecondary = hex("#c6d0dc"),
		FgTertiary = hex("#93a1b2"),
		FgQuaternary = hex("#768596"),
		FgQuinary = hex("#667586"),
		Success = hex("#5fcf8f"),
	},
}
