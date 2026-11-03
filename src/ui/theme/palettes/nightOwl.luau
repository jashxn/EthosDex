local utils = require(script.Parent.utils)
local hex = utils.hex

-- Night Owl: Night Owl, for late-night coding.
return {
	name = "night owl",
	title = "Night Owl",
	BgBaseColor = hex("#011627"),
	AccentPrimary = hex("#82aaff"),
	AccentSecondary = hex("#c792ea"),
	AccentCaution = hex("#ecc48d"),
	AccentDestructive = hex("#ef5350"),
	Overrides = {
		BgSunken = hex("#011627"),
		FgPrimary = hex("#d6deeb"),
		FgSecondary = hex("#bcc6d6"),
		FgTertiary = hex("#8fa0b5"),
		FgQuaternary = hex("#7a8ba0"),
		FgQuinary = hex("#6b7c90"),
		Success = hex("#addb67"),
	},
}
