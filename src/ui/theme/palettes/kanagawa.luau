local utils = require(script.Parent.utils)
local hex = utils.hex

-- Kanagawa: Hokusai's Great Wave: ink blues and old-paper text.
return {
	name = "kanagawa",
	title = "Kanagawa",
	BgBaseColor = hex("#1f1f28"),
	AccentPrimary = hex("#7e9cd8"),
	AccentSecondary = hex("#957fb8"),
	AccentCaution = hex("#e6c384"),
	AccentDestructive = hex("#ff5d62"),
	Overrides = {
		BgSunken = hex("#1f1f28"),
		FgPrimary = hex("#dcd7ba"),
		FgSecondary = hex("#c8c093"),
		FgTertiary = hex("#a6a69c"),
		FgQuaternary = hex("#8f8e86"),
		FgQuinary = hex("#7a7a72"),
		Success = hex("#98bb6c"),
	},
}
