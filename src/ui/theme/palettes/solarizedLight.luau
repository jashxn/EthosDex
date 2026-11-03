local utils = require(script.Parent.utils)
local hex = utils.hex

-- Solarized Light: Solarized on base3.
return {
	name = "solarized light",
	title = "Solarized Light",
	BgBaseColor = hex("#fdf6e3"),
	AccentPrimary = hex("#268bd2"),
	AccentSecondary = hex("#2aa198"),
	AccentCaution = hex("#8a6800"),
	AccentDestructive = hex("#c4291f"),
	Overrides = {
		BgSunken = hex("#fdf6e3"),
		FgPrimary = hex("#073642"),
		FgSecondary = hex("#2f4c54"),
		FgTertiary = hex("#4d636a"),
		FgQuaternary = hex("#5f747a"),
		FgQuinary = hex("#788a8e"),
		Success = hex("#5c6b00"),
	},
}
