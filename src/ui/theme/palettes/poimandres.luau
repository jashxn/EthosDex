local utils = require(script.Parent.utils)
local hex = utils.hex

-- Poimandres: Calm blue-grey with mint and sky accents.
return {
	name = "poimandres",
	title = "Poimandres",
	BgBaseColor = hex("#1b1e28"),
	AccentPrimary = hex("#5de4c7"),
	AccentSecondary = hex("#89ddff"),
	AccentCaution = hex("#fffac2"),
	AccentDestructive = hex("#e07aaf"),
	Overrides = {
		BgSunken = hex("#1b1e28"),
		FgPrimary = hex("#e4f0fb"),
		FgSecondary = hex("#c7d0e0"),
		FgTertiary = hex("#a6accd"),
		FgQuaternary = hex("#8e94b8"),
		FgQuinary = hex("#7d83a6"),
		Success = hex("#5de4c7"),
	},
}
