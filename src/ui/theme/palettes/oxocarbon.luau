local utils = require(script.Parent.utils)
local hex = utils.hex

-- Oxocarbon: IBM Carbon greys with a blue accent.
return {
	name = "oxocarbon",
	title = "Oxocarbon",
	BgBaseColor = hex("#161616"),
	AccentPrimary = hex("#78a9ff"),
	AccentSecondary = hex("#be95ff"),
	AccentCaution = hex("#ffd57e"),
	AccentDestructive = hex("#ee5396"),
	Overrides = {
		BgSunken = hex("#161616"),
		FgPrimary = hex("#f2f4f8"),
		FgSecondary = hex("#dde1e6"),
		FgTertiary = hex("#a8adb5"),
		FgQuaternary = hex("#8d929a"),
		FgQuinary = hex("#7a7f87"),
		Success = hex("#42be65"),
	},
}
