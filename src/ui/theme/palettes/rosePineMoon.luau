local utils = require(script.Parent.utils)
local hex = utils.hex

-- Rosé Pine Moon: Rosé Pine's softer moonlit variant.
return {
	name = "rosé pine moon",
	title = "Rosé Pine Moon",
	BgBaseColor = hex("#232136"),
	AccentPrimary = hex("#c4a7e7"),
	AccentSecondary = hex("#ea9a97"),
	AccentCaution = hex("#f6c177"),
	AccentDestructive = hex("#eb6f92"),
	Overrides = {
		BgSunken = hex("#232136"),
		FgPrimary = hex("#e0def4"),
		FgSecondary = hex("#c7c3e0"),
		FgTertiary = hex("#a09cbc"),
		FgQuaternary = hex("#8b87a8"),
		FgQuinary = hex("#7a7696"),
		Success = hex("#9ccfd8"),
	},
}
