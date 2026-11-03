local utils = require(script.Parent.utils)
local hex = utils.hex

-- Dracula: The classic purple-accented dark theme.
return {
	name = "dracula",
	title = "Dracula",
	BgBaseColor = hex("#282a36"),
	AccentPrimary = hex("#bd93f9"),
	AccentSecondary = hex("#ff79c6"),
	AccentCaution = hex("#f1fa8c"),
	AccentDestructive = hex("#ff6e6e"),
	Overrides = {
		BgSunken = hex("#282a36"),
		FgPrimary = hex("#f8f8f2"),
		FgSecondary = hex("#d6d6e0"),
		FgTertiary = hex("#a9b0d0"),
		FgQuaternary = hex("#8e98c4"),
		FgQuinary = hex("#7a86b8"),
		Success = hex("#50fa7b"),
	},
}
