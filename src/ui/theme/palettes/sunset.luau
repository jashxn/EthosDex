local utils = require(script.Parent.utils)
local hex = utils.hex

-- Sunset: Dusky plum with a coral accent and amber highlights.
return {
	name = "sunset",
	title = "Sunset",
	BgBaseColor = hex("#1a1418"),
	AccentPrimary = hex("#ff7a59"),
	AccentSecondary = hex("#ffb347"),
	AccentCaution = hex("#ffc94d"),
	AccentDestructive = hex("#ff5c8a"),
	Overrides = {
		FgPrimary = hex("#faf1ef"),
		FgSecondary = hex("#dccac7"),
		FgTertiary = hex("#ab9794"),
		FgQuaternary = hex("#8c7976"),
		FgQuinary = hex("#7b6966"),
		Success = hex("#5fd08a"),
	},
}
