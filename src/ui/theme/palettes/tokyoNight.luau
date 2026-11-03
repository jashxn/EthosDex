local utils = require(script.Parent.utils)
local hex = utils.hex

-- Tokyo Night: Night-city navy with a blue accent.
return {
	name = "tokyo night",
	title = "Tokyo Night",
	BgBaseColor = hex("#1a1b26"),
	AccentPrimary = hex("#7aa2f7"),
	AccentSecondary = hex("#bb9af7"),
	AccentCaution = hex("#e0af68"),
	AccentDestructive = hex("#f7768e"),
	Overrides = {
		BgSunken = hex("#1a1b26"),
		FgPrimary = hex("#c0caf5"),
		FgSecondary = hex("#a9b1d6"),
		FgTertiary = hex("#9099c4"),
		FgQuaternary = hex("#7a82b0"),
		FgQuinary = hex("#6b73a0"),
		Success = hex("#9ece6a"),
	},
}
