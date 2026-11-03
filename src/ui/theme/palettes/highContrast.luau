local utils = require(script.Parent.utils)
local hex = utils.hex

-- High contrast: Pure black, white text and a yellow accent. The most legible theme.
return {
	name = "high contrast",
	title = "High contrast",
	BgBaseColor = hex("#000000"),
	AccentPrimary = hex("#ffd400"),
	AccentSecondary = hex("#00e5ff"),
	AccentCaution = hex("#ffb000"),
	AccentDestructive = hex("#ff5c5c"),
	Overrides = {
		BgSunken = hex("#000000"),
		FgPrimary = hex("#ffffff"),
		FgSecondary = hex("#f0f0f0"),
		FgTertiary = hex("#d0d0d0"),
		FgQuaternary = hex("#b8b8b8"),
		FgQuinary = hex("#a8a8a8"),
		Success = hex("#3dff7a"),
	},
}
