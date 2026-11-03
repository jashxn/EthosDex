local utils = require(script.Parent.utils)
local hex = utils.hex

-- Palenight: Material Palenight: lavender-grey with a purple accent.
return {
	name = "palenight",
	title = "Palenight",
	BgBaseColor = hex("#292d3e"),
	AccentPrimary = hex("#c792ea"),
	AccentSecondary = hex("#82aaff"),
	AccentCaution = hex("#ffcb6b"),
	AccentDestructive = hex("#ff6680"),
	Overrides = {
		BgSunken = hex("#292d3e"),
		FgPrimary = hex("#d0d6f0"),
		FgSecondary = hex("#bfc7d5"),
		FgTertiary = hex("#a6accd"),
		FgQuaternary = hex("#8d93b8"),
		FgQuinary = hex("#7b81a6"),
		Success = hex("#c3e88d"),
	},
}
