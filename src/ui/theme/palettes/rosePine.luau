local utils = require(script.Parent.utils)
local hex = utils.hex

-- Rosé Pine: Pine, faux fur and a bit of soho vibes.
return {
	name = "rosé pine",
	title = "Rosé Pine",
	BgBaseColor = hex("#191724"),
	AccentPrimary = hex("#c4a7e7"),
	AccentSecondary = hex("#ebbcba"),
	AccentCaution = hex("#f6c177"),
	AccentDestructive = hex("#eb6f92"),
	Overrides = {
		BgSunken = hex("#191724"),
		FgPrimary = hex("#e0def4"),
		FgSecondary = hex("#c7c3e0"),
		FgTertiary = hex("#908caa"),
		FgQuaternary = hex("#7e7a98"),
		FgQuinary = hex("#6e6a86"),
		Success = hex("#9ccfd8"),
	},
}
