local utils = require(script.Parent.utils)
local hex = utils.hex

-- Coffee: Espresso browns with cream text and a caramel accent.
return {
	name = "coffee",
	title = "Coffee",
	BgBaseColor = hex("#1c1612"),
	AccentPrimary = hex("#d4a056"),
	AccentSecondary = hex("#c27c5a"),
	AccentCaution = hex("#e8b04a"),
	AccentDestructive = hex("#e8645a"),
	Overrides = {
		BgSunken = hex("#18130f"),
		FgPrimary = hex("#f3e9dc"),
		FgSecondary = hex("#d6c6b2"),
		FgTertiary = hex("#a8957f"),
		FgQuaternary = hex("#8a7864"),
		FgQuinary = hex("#796856"),
		Success = hex("#9cc46a"),
	},
}
